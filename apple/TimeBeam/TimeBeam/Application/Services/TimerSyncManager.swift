import os
import Observation
import Foundation
import _Concurrency

#if os(macOS)
import AppKit
import CoreFoundation
#elseif os(iOS)
import UIKit
#endif

@MainActor
@Observable
final class TimerSyncManager {
    static let shared = TimerSyncManager()

    // MARK: - Properties
    private(set) var timer: PomodoroTimer?
    let deviceId: String
    private(set) var isSyncing: Bool = false
    private var queuedSyncNeeded: Bool = false
    private var lastSyncTimestamp: Date = Date.distantPast
    private var syncRetryCount: Int = 0
    private var syncRetryDelay: TimeInterval = 1.0
    private var isNetworkConnected: Bool = true
    private var isDeviceRegistered: Bool = false
    private var syncTimer: _Concurrency.Task<Void, Never>?
    private var actionQueue: [QueuedTimerAction] = []
    private let maxQueueSize = 50
    enum SyncError: Error, LocalizedError {
        case networkFailure(String)
        case authenticationFailure
        case timeout

        var errorDescription: String? {
            switch self {
            case .networkFailure(let message):
                return "Network failure: \(message)"
            case .authenticationFailure:
                return "Authentication failure"
            case .timeout:
                return "Request timeout"
            }
        }
    }

    func getTimer() -> PomodoroTimer? { timer }

    // MARK: - Initialization
    private init() {
        do {
            if let saved = try KeychainStore.loadString(.deviceId), !saved.isEmpty {
                deviceId = saved
            } else {
                let newId = UUID().uuidString
                try KeychainStore.saveString(newId, for: .deviceId)
                deviceId = newId
            }
        } catch {
            print("⚠️ TIMER_SYNC: Failed to load deviceId from Keychain: \(error)")
            deviceId = UUID().uuidString
        }
    }

    func configure(with timer: PomodoroTimer) {
        self.timer = timer
        print("🔧 TIMER_SYNC_CONFIG: Timer configured, deviceId: \(deviceId)")

        // Load persisted action queue from Keychain on startup
        actionQueue = loadActionQueue()
        if !actionQueue.isEmpty {
            print("📋 TIMER_SYNC_QUEUE: Loaded \(actionQueue.count) persisted actions — will drain on next network event")
        }

        // If we had a queued sync request, execute it now
        if queuedSyncNeeded {
            print("🔄 TIMER_SYNC_QUEUED: Executing queued sync")
            queuedSyncNeeded = false
            Task {
                await performSyncTimerState()
            }
        }

        // Start periodic polling for cross-device sync
        startPeriodicPolling()
    }

    // MARK: - Periodic Polling

    private func startPeriodicPolling() {
        syncTimer?.cancel()
        syncTimer = _Concurrency.Task { [weak self] in
            // Poll immediately on configure so a freshly launched device picks up
            // the current state without waiting an interval. APNs push is the
            // primary path; this is the safety net when push is delayed/dropped.
            await self?.pollForRemoteChanges()
            while !_Concurrency.Task.isCancelled {
                try? await _Concurrency.Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                if !_Concurrency.Task.isCancelled {
                    await self?.pollForRemoteChanges()
                }
            }
        }
    }

    private func pollForRemoteChanges() async {
        guard let timer = timer else { return }

        var accessToken = AuthManager.shared.getValidAccessToken()
        if accessToken == nil {
            let refreshed = await AuthManager.shared.refreshAccessToken()
            if refreshed { accessToken = AuthManager.shared.getValidAccessToken() }
        }
        guard let accessToken = accessToken else { return }

        do {
            let pulledState = try await ApiClient.shared.pullTimerState(accessToken: accessToken)
            if let state = pulledState,
               let pulledModified = state.lastModifiedTimestamp?.timeIntervalSince1970,
               pulledModified > timer.lastModifiedTimestamp {
                timer.applySyncedState(
                    phase: Phase(rawValue: state.phase ?? "work") ?? .work,
                    remainingSeconds: state.remainingSeconds ?? 0,
                    isRunning: state.isRunning ?? false,
                    workDuration: state.workDuration ?? 25,
                    breakDuration: state.breakDuration ?? 5,
                    longBreakDuration: state.longBreakDuration ?? 15,
                    autoStartNextSession: state.autoStartNextSession ?? false,
                    shortBreaksCompleted: state.shortBreaksCompleted ?? 0,
                    startTimestamp: state.startTimestamp?.timeIntervalSince1970,
                    pauseTimestamp: state.pauseTimestamp?.timeIntervalSince1970,
                    lastModifiedTimestamp: pulledModified
                )
                print("✅ TIMER_SYNC_POLL: Applied polled state from backend")
            }
        } catch {
            print("⚠️ TIMER_SYNC_POLL: Failed to poll: \(error.localizedDescription)")
        }
    }

    // MARK: - Event-based Sync - Only sync on meaningful actions
    func syncTimerAction(_ action: TimerAction) async {
        print("🚀 TIMER_SYNC_ACTION: syncTimerAction(\(action.rawValue)) called")
        guard timer != nil else {
            print("⚠️ TIMER_SYNC_SKIP: No timer configured yet, queuing for later")
            // Queue the sync to run when timer is configured
            queuedSyncNeeded = true
            return
        }
        await performActionSync(action)
    }

    func syncTimerState() async {
        print("🚀 TIMER_SYNC_STATE: syncTimerState() called for full state sync")
        guard timer != nil else {
            print("⚠️ TIMER_SYNC_SKIP: No timer configured yet, queuing for later")
            queuedSyncNeeded = true
            return
        }
        await performSyncTimerState()
    }

    private func performActionSync(_ action: TimerAction) async {
        guard let timer = timer else { return }
        isSyncing = true
        print("✅ TIMER_SYNC_ACTIVE: Performing action sync for \(action.rawValue)")
        defer { isSyncing = false }

        // Update local timer state FIRST before creating DTO and sending to backend
        switch action {
        case .start:
            timer.start()
        case .pause:
            timer.pause()
        case .reset:
            timer.reset()
        case .stop:
            timer.pause()  // stop is same as pause
        case .advance:
            timer.advance()
        }

        // Perform sync with improved error handling and retry logic
        let success = await syncWithRetry(
            operation: .actionSync(action),
            operationHandler: { [self] accessToken in
                // Push action to backend - send action + timer state + static metadata
                let actionDto = TimerActionDto(
                    action: action.rawValue,
                    phase: timer.phase.rawValue,
                    isRunning: timer.isRunning,
                    remainingSeconds: Int(timer.remainingSeconds),
                    workDuration: timer.workDuration,
                    breakDuration: timer.breakDuration,
                    longBreakDuration: timer.longBreakDuration,
                    autoStartNextSession: timer.autoStartNextSession,
                    shortBreaksCompleted: timer.shortBreaksCompleted,
                    deviceId: self.deviceId,
                    timestamp: Date().timeIntervalSince1970
                )

                print("📤 TIMER_SYNC_ACTION_PUSH: Pushing action - \(action.rawValue), phase: \(timer.phase.rawValue), isRunning: \(timer.isRunning)")

                // Call API directly - URLSession handles timeout
                try await ApiClient.shared.pushTimerAction(actionDto, accessToken: accessToken)
                print("✅ TIMER_SYNC_ACTION_SUCCESS: Successfully pushed action to backend")

                // Only pull state occasionally for conflict resolution
                // This is more efficient than pulling every second
                if self.shouldPullState() {
                    await self.pullLatestState(accessToken: accessToken)
                }
            },
            maxRetries: 3,
            baseDelay: 1.0
        )

        if !success {
            print("❌ TIMER_SYNC_ACTION_FAILED: Failed to push timer action after retries")
            handleSyncFailure("ACTION_SYNC", error: nil as Error?)
        }
    }

    private func performSyncTimerState() async {
        guard timer != nil else { return }
        guard let accessToken = AuthManager.shared.getValidAccessToken() else { return }
        await pullLatestState(accessToken: accessToken)
    }

    @MainActor
    func applyEventState(from userInfo: [AnyHashable: Any]) {
        guard let timer = timer else { return }
        guard let phase = userInfo["phase"] as? String else { return }

        let remainingSecondsInt: Int
        if let i = userInfo["remainingSeconds"] as? Int {
            remainingSecondsInt = i
        } else if let n = userInfo["remainingSeconds"] as? NSNumber {
            remainingSecondsInt = n.intValue
        } else { return }

        let isRunningBool: Bool
        if let b = userInfo["isRunning"] as? Bool {
            isRunningBool = b
        } else if let n = userInfo["isRunning"] as? NSNumber {
            isRunningBool = n.boolValue
        } else { return }

        let startTimestamp = userInfo["startTimestamp"] as? Double
        let pauseTimestamp = (userInfo["pauseTimestamp"] as? Double) ?? (userInfo["pauseTimestamp"] as? NSNumber)?.doubleValue
        let workDuration = userInfo["workDuration"] as? Int ?? 1500
        let breakDuration = userInfo["breakDuration"] as? Int ?? 300
        let longBreakDuration = userInfo["longBreakDuration"] as? Int ?? 900
        let lastModifiedTimestamp = userInfo["lastModifiedTimestamp"] as? Double ?? Date().timeIntervalSince1970

        // Timestamp comparison per D-01: newer wins
        // Skip apply if push timestamp is stale (older than or equal to local)
        if lastModifiedTimestamp <= timer.lastModifiedTimestamp {
            print("⏭️ TIMER_SYNC_EVENT: Push timestamp \(lastModifiedTimestamp) <= local \(timer.lastModifiedTimestamp) — skipping (local state is newer)")
            return
        }

        // Read autoStartNextSession from userInfo payload, not local fallback
        let autoStartNextSession = userInfo["autoStartNextSession"] as? Bool ?? false

        // Read shortBreaksCompleted from userInfo payload, not local fallback
        let shortBreaksCompleted = userInfo["shortBreaksCompleted"] as? Int ?? 0

        timer.applySyncedState(
            phase: Phase(rawValue: phase) ?? .work,
            remainingSeconds: remainingSecondsInt,
            isRunning: isRunningBool,
            workDuration: workDuration,
            breakDuration: breakDuration,
            longBreakDuration: longBreakDuration,
            autoStartNextSession: autoStartNextSession,
            shortBreaksCompleted: shortBreaksCompleted,
            startTimestamp: startTimestamp,
            pauseTimestamp: pauseTimestamp,
            lastModifiedTimestamp: lastModifiedTimestamp
        )
        print("✅ TIMER_SYNC_EVENT: Applied state from push notification - phase: \(phase), remaining: \(remainingSecondsInt), running: \(isRunningBool)")
    }

    // Enhanced sync with retry logic and timeouts
    private func syncWithRetry(
        operation: SyncOperation,
        operationHandler: @escaping (String) async throws -> Void,
        maxRetries: Int,
        baseDelay: TimeInterval
    ) async -> Bool {
        var attempt = 0
        var delay = baseDelay

        while attempt <= maxRetries {
            do {
                print("🔄 TIMER_SYNC_ATTEMPT: Attempt \(attempt + 1) for sync operation")

                // Check if we have a valid access token, attempt refresh if expired
                var accessToken = AuthManager.shared.getValidAccessToken()
                if accessToken == nil {
                    let refreshed = await AuthManager.shared.refreshAccessToken()
                    if refreshed { accessToken = AuthManager.shared.getValidAccessToken() }
                }
                guard let accessToken = accessToken else {
                    throw SyncError.authenticationFailure
                }

                // Register device on first sync
                if !isDeviceRegistered {
                    do {
                        let registration = DeviceRegistrationDto(
                            deviceId: deviceId,
                            deviceName: Self.deviceName(),
                            deviceType: Self.platformName(),
                            platformVersion: ProcessInfo.processInfo.operatingSystemVersionString,
                            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
                            fcmToken: nil
                        )
                        try await ApiClient.shared.registerDevice(registration, accessToken: accessToken)
                        isDeviceRegistered = true
                        print("✅ TIMER_SYNC_DEVICE: Registered device \(deviceId) on platform \(Self.platformName())")
                    } catch {
                        print("⚠️ TIMER_SYNC_DEVICE: Failed to register device: \(error.localizedDescription)")
                        // Don't fail the entire sync if registration fails
                    }
                }

                // Execute the sync operation
                try await operationHandler(accessToken)

                // Success - reset retry counters
                syncRetryCount = 0
                syncRetryDelay = 1.0
                return true

            } catch {
                print("❌ TIMER_SYNC_ERROR: Sync attempt failed: \(error.localizedDescription)")

                // Handle specific error cases for retry logic
                if shouldRetry(error, attempt: attempt) {
                    attempt += 1
                    if attempt <= maxRetries {
                        let nextDelay = min(delay * 2, 30.0) // Cap at 30 seconds
                        print("⏳ TIMER_SYNC_RETRY: Retrying in \(nextDelay) seconds...")
                        try? await Task.sleep(nanoseconds: UInt64(nextDelay * 1_000_000_000))
                        delay = nextDelay
                    }
                    continue
                } else {
                    print("🛑 TIMER_SYNC_ABORT: Skipping retries due to non-retryable error")
                    break
                }
            }
        }

        print("❌ TIMER_SYNC_MAX_RETRIES: Reached maximum retry attempts (\(maxRetries))")
        return false
    }

    private func shouldRetry(_ error: Error, attempt: Int) -> Bool {
        // Don't retry on authentication failures
        if let syncError = error as? SyncError,
           case .authenticationFailure = syncError {
            return false
        }

        // Don't retry on certain network errors (non-retryable)
        if let networkError = error as? ApiClient.ApiError,
           case .networkError(let message) = networkError,
           message.contains("Unauthorized") || message.contains("invalid_token") {
            return false
        }

        // Retry on network errors, timeouts, and transient failures
        return attempt < 3
    }

    private func pullLatestState(accessToken: String) async {
        guard let timer = timer else { return }

        // Pull state with retry logic
        let success = await syncWithRetry(
            operation: .stateSync,
            operationHandler: { [self] _ in
                // Validate that we have a valid access token
                guard let accessToken = AuthManager.shared.getValidAccessToken() else {
                    throw SyncError.authenticationFailure
                }

                // Pull the state from backend
                let pulledState = try await ApiClient.shared.pullTimerState(accessToken: accessToken)

                // Validate the pulled state before applying
                guard let validatedState = self.validatePulledState(pulledState) else {
                    print("❌ TIMER_SYNC_PULL_VALIDATE: Invalid state received from backend, skipping update")
                    return
                }

                // Diagnostic logging for pulled state
                print("📥 TIMER_SYNC_PULL: Received state - phase: \(validatedState.phase ?? "unknown"), remaining: \(validatedState.remainingSeconds ?? -1), running: \(validatedState.isRunning ?? false), device: \(validatedState.deviceId ?? "unknown")")
                print("📥 TIMER_SYNC_PULL: Pulled timestamps - start: \(validatedState.startTimestamp?.timeIntervalSince1970 ?? 0), lastModified: \(validatedState.lastModifiedTimestamp?.timeIntervalSince1970 ?? 0)")

                // Use Date directly for comparison (already parsed by JSONDecoder)
                let currentModified = timer.lastModifiedTimestamp
                let pulledModified = validatedState.lastModifiedTimestamp?.timeIntervalSince1970 ?? 0

                print("📊 TIMER_SYNC_COMPARE: Current modified: \(currentModified), Pulled modified: \(pulledModified), Should sync: \(currentModified < pulledModified)")

                // Apply if more recent and state is valid
                if timer.lastModifiedTimestamp < pulledModified {
                    // For cross-device sync, use the exact remainingSeconds from the remote state
                    // instead of trying to recalculate based on timestamps
                    print("✅ TIMER_SYNC_APPLY: Applying synced state to local timer")

                    // Apply the validated state to local timer
                    timer.applySyncedState(
                        phase: Phase(rawValue: validatedState.phase ?? "work") ?? .work,
                        remainingSeconds: validatedState.remainingSeconds ?? 0,
                        isRunning: validatedState.isRunning ?? false,
                        workDuration: validatedState.workDuration ?? 1500,
                        breakDuration: validatedState.breakDuration ?? 300,
                        longBreakDuration: validatedState.longBreakDuration ?? 900,
                        autoStartNextSession: validatedState.autoStartNextSession ?? false,
                        shortBreaksCompleted: validatedState.shortBreaksCompleted ?? 0,
                        startTimestamp: validatedState.startTimestamp?.timeIntervalSince1970,
                        pauseTimestamp: validatedState.pauseTimestamp?.timeIntervalSince1970,
                        lastModifiedTimestamp: pulledModified
                    )
                    print("✅ TIMER_SYNC_APPLY: State applied successfully")

                    self.lastSyncTimestamp = Date()
                } else {
                    self.lastSyncTimestamp = Date()
                }
            },
            maxRetries: 2,
            baseDelay: 1.0
        )

        if !success {
            print("❌ TIMER_SYNC_PULL_FAILED: Failed to pull latest timer state after retries")
            handleSyncFailure("STATE_PULL", error: nil as Error?)
        }
    }

    /**
     * Validates the pulled state for data integrity and correctness
     * This ensures the state being applied is safe and consistent
     */
    private func validatePulledState(_ state: TimerStateDto?) -> TimerStateDto? {
        // Return early if state is nil
        guard let state = state else {
            print("⚠️ TIMER_SYNC_VALIDATE: Received nil state, skipping validation")
            return nil
        }

        // Basic validation of required fields
        if state.phase == nil {
            print("❌ TIMER_SYNC_VALIDATE: State missing phase, rejecting")
            return nil
        }

        // Validate phase is valid
        if let phase = state.phase, !Phase.allCases.map({ $0.rawValue }).contains(phase) {
            print("❌ TIMER_SYNC_VALIDATE: Invalid phase '\(phase)' received, rejecting")
            return nil
        }

        // Validate numeric fields are within reasonable bounds
        if let remainingSeconds = state.remainingSeconds {
            if remainingSeconds < 0 || remainingSeconds > 3600 { // Max 1 hour
                print("❌ TIMER_SYNC_VALIDATE: Invalid remainingSeconds \(remainingSeconds), rejecting")
                return nil
            }
        }

        // Validate work duration is within reasonable bounds
        if let workDuration = state.workDuration {
            if workDuration < 60 || workDuration > 3600 { // Min 1 minute, max 60 minutes
                print("❌ TIMER_SYNC_VALIDATE: Invalid workDuration \(workDuration), rejecting")
                return nil
            }
        }

        // Validate break duration is within reasonable bounds
        if let breakDuration = state.breakDuration {
            if breakDuration < 60 || breakDuration > 1800 { // Min 1 minute, max 30 minutes
                print("❌ TIMER_SYNC_VALIDATE: Invalid breakDuration \(breakDuration), rejecting")
                return nil
            }
        }

        // Validate long break duration is within reasonable bounds
        if let longBreakDuration = state.longBreakDuration {
            if longBreakDuration < 60 || longBreakDuration > 3600 { // Min 1 minute, max 60 minutes
                print("❌ TIMER_SYNC_VALIDATE: Invalid longBreakDuration \(longBreakDuration), rejecting")
                return nil
            }
        }

        // If all validations pass, return the state
        print("✅ TIMER_SYNC_VALIDATE: State passed all validation checks")
        return state
    }

    private func shouldPullState() -> Bool {
        // Only pull state for conflict resolution when needed, not every time
        // We can do this occasionally or when we detect significant differences
        let now = Date()
        let timeSinceLastSync = now.timeIntervalSince(lastSyncTimestamp)
        let should = timeSinceLastSync > 30 || lastSyncTimestamp == Date.distantPast
        return should
    }

    func updateLastSyncTimestamp() {
        lastSyncTimestamp = Date()
    }

    // MARK: - Enhanced Error Handling
    private func handleSyncFailure(_ syncType: String, error: Error?) {
        // Increment retry counter
        syncRetryCount += 1
        syncRetryDelay = min(syncRetryDelay * 2, 30.0) // Exponential backoff up to 30s

        // Log error details
        if let error = error {
            print("💥 TIMER_SYNC_ERROR: \(syncType) failed with error: \(error.localizedDescription)")
            LoggerStore.timer.error("Timer sync failed - \(syncType): \(error.localizedDescription)")
        } else {
            print("💥 TIMER_SYNC_ERROR: \(syncType) failed with unknown error")
            LoggerStore.timer.error("Timer sync failed - \(syncType): Unknown error")
        }

        // Trigger fallback mechanisms if needed
        if syncRetryCount >= 3 {
            print("⚠️ TIMER_SYNC_FALLBACK: Triggering fallback mechanisms after \(syncRetryCount) failed attempts")
            // In a real implementation, we might trigger fallback logic like offline queueing
        }
    }

    // MARK: - Incoming Action Handling (Event-Based Sync)

    /**
     * Handle incoming timer action from another device
     * This implements event-based synchronization where actions are interpreted and applied
     */
    func applyIncomingAction(
        _ action: String,
        phase: String,
        isRunning: Bool,
        workDuration: Int,
        breakDuration: Int,
        longBreakDuration: Int,
        autoStartNextSession: Bool,
        shortBreaksCompleted: Int,
        sourceDeviceId: String,
        timestamp: Double
    ) {
        guard let timer = timer else {
            print("⚠️ TIMER_SYNC_ACTION: No timer configured, cannot apply incoming action")
            return
        }

        // Ignore actions from self (prevent feedback loop)
        if sourceDeviceId == deviceId {
            print("⏭️ TIMER_SYNC_ACTION: Ignoring own action from device \(deviceId)")
            return
        }

        print("📥 TIMER_SYNC_ACTION_IN: Received action '\(action)' from device \(sourceDeviceId), phase: \(phase)")

        // Apply action based on type
        switch action.lowercased() {
        case "start":
            // Start timer: set running=true, calculate remainingSeconds from phase and duration
            timer.applySyncedState(
                phase: Phase(rawValue: phase) ?? .work,
                remainingSeconds: calculateRemainingSecondsForPhase(phase, workDuration: workDuration, breakDuration: breakDuration, longBreakDuration: longBreakDuration),
                isRunning: true,
                workDuration: workDuration,
                breakDuration: breakDuration,
                longBreakDuration: longBreakDuration,
                autoStartNextSession: autoStartNextSession,
                shortBreaksCompleted: shortBreaksCompleted,
                startTimestamp: Date().timeIntervalSince1970,
                pauseTimestamp: nil,
                lastModifiedTimestamp: timestamp
            )
            print("✅ TIMER_SYNC_ACTION_APPLY: Applied START action")

        case "pause":
            // Pause timer: keep current state, just stop running
            timer.pause()
            print("✅ TIMER_SYNC_ACTION_APPLY: Applied PAUSE action")

        case "reset":
            // Reset timer: set running=false, reset remainingSeconds to phase duration
            timer.applySyncedState(
                phase: Phase(rawValue: phase) ?? .work,
                remainingSeconds: calculateRemainingSecondsForPhase(phase, workDuration: workDuration, breakDuration: breakDuration, longBreakDuration: longBreakDuration),
                isRunning: false,
                workDuration: workDuration,
                breakDuration: breakDuration,
                longBreakDuration: longBreakDuration,
                autoStartNextSession: autoStartNextSession,
                shortBreaksCompleted: 0,
                startTimestamp: nil,
                pauseTimestamp: nil,
                lastModifiedTimestamp: timestamp
            )
            print("✅ TIMER_SYNC_ACTION_APPLY: Applied RESET action")

        case "stop":
            // Stop timer: just pause, don't reset
            timer.pause()
            print("✅ TIMER_SYNC_ACTION_APPLY: Applied STOP action")

        case "advance":
            // Advance to next phase
            timer.advance()
            print("✅ TIMER_SYNC_ACTION_APPLY: Applied ADVANCE action")

        default:
            print("⚠️ TIMER_SYNC_ACTION: Unknown action type: \(action)")
        }
    }

    /**
     * Calculate remainingSeconds based on phase and durations
     * This ensures timers start with correct duration when synced
     */
    private func calculateRemainingSecondsForPhase(_ phase: String, workDuration: Int, breakDuration: Int, longBreakDuration: Int) -> Int {
        switch phase.lowercased() {
        case "work":
            return workDuration
        case "break", "short_break":
            return breakDuration
        case "long_break", "longbreak":
            return longBreakDuration
        default:
            return workDuration // Default to work duration
        }
    }

    // MARK: - Watch Connectivity
    func applyIncomingState(_ stateDict: [String: Any]) {
        guard let timer = timer else { return }

        let startTimestamp = stateDict["startTimestamp"] as? Double
        let pauseTimestamp = stateDict["pauseTimestamp"] as? Double
        let totalDuration = stateDict["totalDuration"] as? Int ?? 1500
        let remainingSeconds = stateDict["remainingSeconds"] as? Int ?? totalDuration
        let phaseRaw = stateDict["phase"] as? String ?? "work"
        let isRunning = stateDict["isRunning"] as? Bool ?? false
        let workDuration = stateDict["workDuration"] as? Int ?? 25
        let breakDuration = stateDict["breakDuration"] as? Int ?? 5
        let longBreakDuration = stateDict["longBreakDuration"] as? Int ?? 15
        let autoStartNextSession = stateDict["autoStartNextSession"] as? Bool ?? false
        let shortBreaksCompleted = stateDict["shortBreaksCompleted"] as? Int ?? 0
        let lastModifiedTimestamp: Double
        if let timestamp = stateDict["lastModifiedTimestamp"] as? Double {
            lastModifiedTimestamp = timestamp
        } else if let dateTimestamp = stateDict["lastModifiedTimestamp"] as? Date {
            lastModifiedTimestamp = dateTimestamp.timeIntervalSince1970
        } else {
            lastModifiedTimestamp = Date().timeIntervalSince1970
        }

        // Apply if more recent
        if timer.lastModifiedTimestamp < lastModifiedTimestamp {
            timer.applySyncedState(
                phase: Phase(rawValue: phaseRaw) ?? .work,
                remainingSeconds: remainingSeconds,
                isRunning: isRunning,
                workDuration: workDuration,
                breakDuration: breakDuration,
                longBreakDuration: longBreakDuration,
                autoStartNextSession: autoStartNextSession,
                shortBreaksCompleted: shortBreaksCompleted,
                startTimestamp: startTimestamp,
                pauseTimestamp: pauseTimestamp,
                lastModifiedTimestamp: lastModifiedTimestamp
            )
            print("✅ TIMER_SYNC_APPLY: Applied incoming synced state")
        } else {
            print("⏭️ TIMER_SYNC_SKIP: Local state is more recent")
        }
    }

    // MARK: - Device Identification

    private static func deviceName() -> String {
        #if os(macOS)
        return ProcessInfo.processInfo.hostName
        #elseif os(iOS)
        return UIDevice.current.name
        #else
        return "Unknown Device"
        #endif
    }

    private static func platformName() -> String {
        #if os(macOS)
        return "macOS"
        #elseif os(iOS)
        return "iOS"
        #else
        return "unknown"
        #endif
    }

    // MARK: - Action Queue Management

    func enqueueAction(_ action: QueuedTimerAction) {
        if actionQueue.count >= maxQueueSize {
            print("⚠️ TIMER_SYNC_QUEUE: Queue at max size (\(maxQueueSize)), dropping oldest action")
            actionQueue.removeFirst()
        }
        actionQueue.append(action)
        persistActionQueue()
    }

    private func persistActionQueue() {
        guard !actionQueue.isEmpty else {
            print("💾 TIMER_SYNC_QUEUE: Queue is empty, skipping persist")
            return
        }

        do {
            let encoded = try JSONEncoder().encode(actionQueue)
            try KeychainStore.save(encoded, for: .actionQueue)
            print("💾 TIMER_SYNC_QUEUE: Persisted \(actionQueue.count) actions to Keychain")
        } catch {
            print("❌ TIMER_SYNC_QUEUE_PERSIST: Failed to persist queue: \(error.localizedDescription)")
        }
    }

    func loadActionQueue() -> [QueuedTimerAction] {
        do {
            guard let data = try KeychainStore.load(.actionQueue) else {
                print("📋 TIMER_SYNC_QUEUE: No persisted queue in Keychain")
                return []
            }
            let decoded = try JSONDecoder().decode([QueuedTimerAction].self, from: data)
            print("📋 TIMER_SYNC_QUEUE: Loaded \(decoded.count) actions from Keychain")
            return decoded
        } catch {
            print("❌ TIMER_SYNC_QUEUE_LOAD: Failed to load queue: \(error.localizedDescription)")
            return []
        }
    }

    func clearActionQueue() {
        actionQueue.removeAll()
        do {
            try KeychainStore.clear(.actionQueue)
            print("🗑️ TIMER_SYNC_QUEUE: Cleared action queue from Keychain")
        } catch {
            print("❌ TIMER_SYNC_QUEUE_CLEAR: Failed to clear queue: \(error.localizedDescription)")
        }
    }

    // MARK: - Internal Enum
    private enum SyncOperation {
        case stateSync
        case actionSync(TimerAction)
    }
}
