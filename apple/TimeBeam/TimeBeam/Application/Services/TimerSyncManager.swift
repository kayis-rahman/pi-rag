import os
import SwiftUI
import Foundation
import _Concurrency

// MARK: - Timer Action Enum
enum TimerAction: String, Codable {
    case start = "start"
    case pause = "pause"
    case reset = "reset"
    case stop = "stop"
    case advance = "advance"
}

@MainActor
final class TimerSyncManager: ObservableObject {
    static let shared = TimerSyncManager()

    @Published var isSyncing: Bool = false

    var deviceId: String
    private var timer: PomodoroTimer?
    private var queuedSyncNeeded: Bool = false
    private var deviceRegistered: Bool = false
    private var lastSyncTimestamp: Date = Date.distantPast
    
    func getTimer() -> PomodoroTimer? { timer }

    // MARK: - Initialization
    private init() {
        deviceId = UUID().uuidString
    }

    func configure(with timer: PomodoroTimer) {
        self.timer = timer
        print("🔧 TIMER_SYNC_CONFIG: Timer configured, deviceId: \(deviceId)")

        // If we had a queued sync request, execute it now
        if queuedSyncNeeded {
            print("🔄 TIMER_SYNC_QUEUED: Executing queued sync")
            queuedSyncNeeded = false
            Task {
                await performSyncTimerState()
            }
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

        do {
            guard let accessToken = AuthManager.shared.getValidAccessToken() else {
                LoggerStore.timer.error("No access token available for sync")
                print("❌ TIMER_SYNC: No access token available from any source")
                return
            }

            // Push action to backend - only send action + static metadata (no continuously changing fields)
            let actionDto = ApiClient.TimerActionDto(
                action: action.rawValue,
                phase: timer.phase.rawValue,
                isRunning: timer.isRunning,
                workDuration: timer.workDuration,
                breakDuration: timer.breakDuration,
                longBreakDuration: timer.longBreakDuration,
                autoStartNextSession: timer.autoStartNextSession,
                shortBreaksCompleted: timer.shortBreaksCompleted,
                deviceId: deviceId,
                timestamp: Date().timeIntervalSince1970
            )

            print("📤 TIMER_SYNC_ACTION_PUSH: Pushing action - \(action.rawValue), phase: \(timer.phase.rawValue), isRunning: \(timer.isRunning)")
            try await ApiClient.shared.pushTimerAction(actionDto, accessToken: accessToken)

            // Only pull state occasionally for conflict resolution
            // This is more efficient than pulling every second
            if shouldPullState() {
                await pullLatestState(accessToken: accessToken)
            }

        } catch {
            LoggerStore.timer.error("Failed to sync timer action: \(error.localizedDescription)")
        }
    }

    private func performSyncTimerState() async {
        guard let timer = timer else { return }
        isSyncing = true
        print("✅ TIMER_SYNC_ACTIVE: Starting full state sync process")
        defer { isSyncing = false }

        do {
            guard let accessToken = AuthManager.shared.getValidAccessToken() else {
                LoggerStore.timer.error("No access token available for sync")
                print("❌ TIMER_SYNC: No access token available from any source")
                return
            }

            // Diagnostic logging for token loading
            print("✅ TIMER_SYNC: Access token loaded, length: \(accessToken.count)")
            print("✅ TIMER_SYNC: Token prefix: \(accessToken.prefix(20))...")

            // Push current state to backend
            let stateDto = ApiClient.TimerStateDto(
                phase: timer.phase.rawValue,
                remainingSeconds: Int(timer.remainingSeconds),
                isRunning: timer.isRunning,
                workDuration: timer.workDuration,
                breakDuration: timer.breakDuration,
                longBreakDuration: timer.longBreakDuration,
                autoStartNextSession: timer.autoStartNextSession,
                shortBreaksCompleted: timer.shortBreaksCompleted,
                totalDuration: Int(timer.currentDuration),
                lastModifiedTimestamp: timer.lastModifiedTimestamp,
                deviceId: deviceId, startTimestamp: timer.startTimestamp ?? 0,
                pauseTimestamp: timer.pauseTimestamp ?? 0
            )

            // Diagnostic logging for timer state being pushed
            print("📤 TIMER_SYNC_PUSH: Pushing state - phase: \(timer.phase.rawValue), remaining: \(timer.remainingSeconds), running: \(timer.isRunning), device: \(deviceId)")

            try await ApiClient.shared.pushTimerState(stateDto, accessToken: accessToken)

            // Pull latest state from backend for conflict resolution (only when needed)
            await pullLatestState(accessToken: accessToken)
            
        } catch {
            LoggerStore.timer.error("Failed to sync timer state: \(error.localizedDescription)")
        }
    }
    
    private func pullLatestState(accessToken: String) async {
        guard let timer = timer else { return }
        
        do {
            if let pulledState = try await ApiClient.shared.pullTimerState(accessToken: accessToken) {
                // Diagnostic logging for pulled state
                print("📥 TIMER_SYNC_PULL: Received state - phase: \(pulledState.phase ?? "unknown"), remaining: \(pulledState.remainingSeconds ?? -1), running: \(pulledState.isRunning ?? false), device: \(pulledState.deviceId ?? "unknown")")
                print("📥 TIMER_SYNC_PULL: Pulled timestamps - start: \(pulledState.startTimestamp ?? 0), lastModified: \(pulledState.lastModifiedTimestamp ?? 0))")

                // Use Date directly for comparison (already parsed by JSONDecoder)
                let currentModified = timer.lastModifiedTimestamp
                let pulledModified = pulledState.lastModifiedTimestamp

                print("📊 TIMER_SYNC_COMPARE: Current modified: \(currentModified), Pulled modified: \(pulledModified ?? 0), Should sync: \(currentModified < (pulledModified ?? 0))")

                // Apply if more recent
                if timer.lastModifiedTimestamp < (pulledState.lastModifiedTimestamp ?? 0) {
                    // For cross-device sync, use the exact remainingSeconds from the remote state
                    // instead of trying to recalculate based on timestamps
                    print("✅ TIMER_SYNC_APPLY: Applying synced state to local timer")
                    timer.applySyncedState(
                        phase: Phase(rawValue: pulledState.phase ?? "work") ?? .work,
                        remainingSeconds: pulledState.remainingSeconds ?? 0,
                        isRunning: pulledState.isRunning ?? false,
                        workDuration: pulledState.workDuration ?? 25,
                        breakDuration: pulledState.breakDuration ?? 5,
                        longBreakDuration: pulledState.longBreakDuration ?? 15,
                        autoStartNextSession: pulledState.autoStartNextSession ?? false,
                        shortBreaksCompleted: pulledState.shortBreaksCompleted ?? 0,
                        startTimestamp: pulledState.startTimestamp ?? 0,
                        pauseTimestamp: pulledState.pauseTimestamp ?? 0,
                        lastModifiedTimestamp: pulledState.lastModifiedTimestamp ?? 0
                    )
                    print("✅ TIMER_SYNC_APPLY: State applied successfully")
                    
                    self.lastSyncTimestamp = Date()
                } else {
                    self.lastSyncTimestamp = Date()
                }
            }
        } catch {
            LoggerStore.timer.error("Failed to pull latest timer state: \(error.localizedDescription)")
        }
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
        }
    }
}

