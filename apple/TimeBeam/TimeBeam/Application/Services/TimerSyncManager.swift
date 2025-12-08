import Foundation
import os

import SwiftUI
import SystemConfiguration

#if os(iOS)
import UIKit
#endif

#if os(watchOS)
import WatchKit
#endif

#if os(iOS)
#endif

#if os(watchOS)
#endif

#if os(macOS)
#endif

@MainActor
final class TimerSyncManager: ObservableObject {
    static let shared = TimerSyncManager()

    // MARK: - Timer Actions
    enum TimerAction: String, Codable {
        case start
        case pause
        case stop
        case reset
    }

    // MARK: - Action Message
    struct ActionMessage: Codable {
        let action: TimerAction
        let timestamp: Date
        let deviceId: String
    }

    // MARK: - Properties
    @AppStorage("deviceId") private var _deviceId = UUID().uuidString

    // MARK: - Public Accessors
    var deviceId: String {
        _deviceId
    }

    private var timer: PomodoroTimer?
    private var queuedActions: [QueuedAction] = []
    private var isOnline = true
    private var lastActionTimestamp: Date?
    private var isDeviceRegistered = false
    private let queue = DispatchQueue(label: "com.timebeam.sync", qos: .background)

    // MARK: - Initialization
    private init() {
        loadQueuedActions()
    }

    func configure(with timer: PomodoroTimer) {
        self.timer = timer
        setupSyncListeners()
    }

    // MARK: - Public Interface
    func syncAction(_ action: TimerAction) {
        let timestamp = Date()
        AppLogger.logSyncEvent("action_sync", details: "\(action.rawValue)")

        // Execute action locally first
        executeAction(action)

        // Queue for offline handling
        queueAction(action, timestamp: timestamp)

        // Broadcast to other devices
        if isOnline {
            broadcastAction(action, timestamp: timestamp)
        }
    }

    func handleIncomingAction(_ action: TimerAction, from deviceId: String, timestamp: Date) {
        // Ignore our own actions
        if deviceId == self.deviceId { return }

        // Only process if this action is newer than our last processed action
        if let lastTimestamp = lastActionTimestamp, timestamp <= lastTimestamp {
            AppLogger.debug("Ignoring older action: \(action.rawValue) from \(deviceId)", category: .sync)
            return
        }

        AppLogger.info("Executing incoming action: \(action.rawValue)", category: .sync)
        executeAction(action)
        lastActionTimestamp = timestamp
    }

    // MARK: - Private Methods
    private func setupSyncListeners() {
        // Network reachability monitoring would go here
        isOnline = true
    }

    private func executeAction(_ action: TimerAction) {
        guard let timer = timer else { return }

        switch action {
        case .start:
            if !timer.isRunning {
                timer.start()
            }
        case .pause:
            if timer.isRunning {
                timer.pause()
            }
        case .stop:
            timer.pause()
            timer.reset()
        case .reset:
            timer.reset()
        }
    }

    // MARK: - Action Queuing
    private struct QueuedAction: Codable {
        let action: TimerAction
        let timestamp: Date
        let id: UUID
    }

    private func queueAction(_ action: TimerAction, timestamp: Date) {
        let queuedAction = QueuedAction(
            action: action,
            timestamp: timestamp,
            id: UUID()
        )

        queue.async {
            self.queuedActions.append(queuedAction)
            self.saveQueuedActions()
        }
    }

    private func processQueuedActions() {
        guard isOnline && !queuedActions.isEmpty else { return }

        AppLogger.debug("Processing \(queuedActions.count) queued actions", category: .sync)

        queue.async {
            let actionsToProcess = self.queuedActions
            self.queuedActions.removeAll()
            self.saveQueuedActions()

            // Send to backend
            for queuedAction in actionsToProcess {
                self.sendActionToBackend(queuedAction.action, timestamp: queuedAction.timestamp)
            }
        }
    }

    private func loadQueuedActions() {
        queue.async {
            if let data = UserDefaults.standard.data(forKey: "queuedSyncActions"),
               let actions = try? JSONDecoder().decode([QueuedAction].self, from: data) {
                self.queuedActions = actions
                AppLogger.debug("Loaded \(actions.count) queued actions", category: .sync)
            }
        }
    }

    private func saveQueuedActions() {
        if let data = try? JSONEncoder().encode(queuedActions) {
            UserDefaults.standard.set(data, forKey: "queuedSyncActions")
        }
    }

    // MARK: - Platform-Specific Broadcasting
    private func broadcastAction(_ action: TimerAction, timestamp: Date) {
        let message = ActionMessage(action: action, timestamp: timestamp, deviceId: deviceId)

        #if os(iOS)
        // Send to watchOS via WatchConnectivity
        WatchConnectivityManager.shared?.broadcastTimerAction(message)

        // Send to backend for macOS sync
        sendActionToBackend(action, timestamp: timestamp)
        #elseif os(macOS)
        // Send to backend for iOS/watchOS sync
        sendActionToBackend(action, timestamp: timestamp)
        #elseif os(watchOS)
        // Send to iOS via WatchConnectivity
        WatchConnectivityManager.shared?.broadcastTimerAction(message)
        #endif

        processQueuedActions()
    }

    // MARK: - Smart Sync with Pull-First Priority
    func smartSyncWithBackend() async {
        AppLogger.logSyncEvent("smart_sync_started")

        guard let accessToken = try? KeychainStore.loadString(.accessToken),
              let config = ApiClient.Configuration.fromInfoPlist() else {
            AppLogger.error("Missing access token or API config", category: .sync)
            return
        }

        AppLogger.debug("Access token found, API config loaded", category: .sync)

        let apiClient = ApiClient(configuration: config)

        do {
            // Register device first if not already registered
            if !isDeviceRegistered {
                await registerDeviceIfNeeded(accessToken: accessToken, apiClient: apiClient)
            }

            // PULL-FIRST APPROACH: Always pull backend state first on startup/sync
            AppLogger.logAPIEvent("timer_state_pull_requested", url: "/api/sessions/timer/state")
            let backendState = try await apiClient.pullTimerState(accessToken: accessToken)

            if let backend = backendState {
                AppLogger.debug("Backend state timestamp: \(backend.timestamp), phase: \(backend.phase)", category: .sync)

                // Apply backend state locally - this becomes the authoritative state
                AppLogger.logSyncEvent("applying_backend_state", details: "pull-first sync approach")
                await applyBackendStateToLocal(backend)

                // Note: We don't push local state on startup anymore
                // Local state pushing only happens in response to user actions via syncAction()

            } else {
                // No backend state exists - this device becomes the master
                AppLogger.logSyncEvent("no_backend_state", details: "becoming master device")
                AppLogger.debug("Initiating local state push as master device", category: .sync)
                await pushLocalStateToBackend(accessToken: accessToken, apiClient: apiClient)
            }

        } catch {
            AppLogger.error("Failed smart sync: \(error.localizedDescription)", category: .sync)
            if let urlError = error as? URLError {
                AppLogger.error("URL Error: \(urlError.localizedDescription)", category: .api)
            }
        }
    }

    // MARK: - Device Registration
    private func registerDeviceIfNeeded(accessToken: String, apiClient: ApiClient) async {
        guard !isDeviceRegistered else { return }

        let deviceRegistration = ApiClient.DeviceRegistrationDto(
            deviceId: deviceId,
            deviceName: getDeviceName(),
            deviceType: getDeviceType(),
            platformVersion: getPlatformVersion(),
            appVersion: getAppVersion(),
            fcmToken: nil // APN token is registered separately via app delegate
        )

        do {
            try await apiClient.registerDevice(deviceRegistration, accessToken: accessToken)
            isDeviceRegistered = true
            AppLogger.logSyncEvent("device_registered", details: "Device successfully registered with backend")
        } catch {
            AppLogger.error("Failed to register device: \(error.localizedDescription)", category: .sync)
            // Don't fail the sync if device registration fails - timer sync can still work
        }
    }

    private func getDeviceName() -> String {
        #if os(iOS)
        return UIDevice.current.name
        #elseif os(macOS)
        return Host.current().localizedName ?? "Mac"
        #elseif os(watchOS)
        return WKInterfaceDevice.current().name
        #else
        return "Unknown Device"
        #endif
    }

    private func getDeviceType() -> String {
        #if os(iOS)
        return "ios"
        #elseif os(macOS)
        return "macos"
        #elseif os(watchOS)
        return "watchos"
        #else
        return "unknown"
        #endif
    }

    private func getPlatformVersion() -> String? {
        #if os(iOS)
        return UIDevice.current.systemVersion
        #elseif os(macOS)
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
        #elseif os(watchOS)
        return WKInterfaceDevice.current().systemVersion
        #else
        return nil
        #endif
    }

    private func getAppVersion() -> String? {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }

    // MARK: - Backend State Sync (Legacy - kept for compatibility)
    func pullLatestStateFromBackend() async {
        AppLogger.debug("Legacy pullLatestStateFromBackend called - redirecting to smart sync", category: .sync)
        await smartSyncWithBackend()
    }

    // MARK: - Helper Methods
    private func getLocalTimerStateWithTimestamp() -> (phase: Phase, timestamp: Date) {
        guard let timer = self.timer else {
            AppLogger.warning("No timer instance, returning default state", category: .sync)
            return (.work, Date.distantPast)
        }

        // Get the phase from saved state if available, but ALWAYS use current timestamp for sync
        if let savedData = UserDefaults.standard.data(forKey: "PomodoroTimerState.v2"),
           let savedState = try? JSONDecoder().decode(PomodoroTimer.TimerState.self, from: savedData) {
            // Use saved phase but current timestamp to avoid old timestamp issues
            return (savedState.phase, Date())
        }

        // Fallback to current timer phase with current timestamp
        AppLogger.debug("No saved state found, using current timer phase", category: .sync)
        return (timer.phase, Date())
    }

    private func pushLocalStateToBackend(accessToken: String, apiClient: ApiClient) async {
        guard let timer = self.timer else {
            AppLogger.warning("No timer to push to backend", category: .sync)
            return
        }

        AppLogger.logSyncEvent("pushing_local_state")

        // Get current timer state with proper values
        let (phase, timestamp) = getLocalTimerStateWithTimestamp()

        // Create proper timer state DTO with actual timer data
        let stateDto = ApiClient.TimerStateDto(
            phase: phase.rawValue,
            remainingSeconds: timer.remainingSeconds,
            isRunning: timer.isRunning,
            workDuration: timer.workDuration,
            breakDuration: timer.breakDuration,
            longBreakDuration: timer.longBreakDuration,
            autoStartNextSession: timer.autoStartNextSession,
            shortBreaksCompleted: timer.shortBreaksCompleted,
            timestamp: timestamp,
            deviceId: deviceId
        )

        AppLogger.debug("Timer state DTO: phase=\(stateDto.phase), remaining=\(stateDto.remainingSeconds), running=\(stateDto.isRunning), deviceId=\(stateDto.deviceId)", category: .sync)

        do {
            try await apiClient.pushTimerState(stateDto, accessToken: accessToken)
            AppLogger.logSyncEvent("local_state_push_success")
        } catch let error as ApiClient.ApiError {
            // Handle specific API errors with detailed logging
            switch error {
            case .httpStatus(let code, let body):
                AppLogger.error("HTTP error pushing timer state: status=\(code), body=\(body ?? "nil")", category: .sync)
                if code == 0 {
                    AppLogger.error("Network connectivity issue - status code 0 indicates connection failure", category: .sync)
                } else if code >= 400 && code < 500 {
                    AppLogger.error("Client error - check request format and authentication", category: .sync)
                } else if code >= 500 {
                    AppLogger.error("Server error - backend may be experiencing issues", category: .sync)
                }
            case .invalidResponse:
                AppLogger.error("Invalid response format from backend", category: .sync)
            case .missingConfiguration:
                AppLogger.error("API configuration missing", category: .sync)
            }
        } catch {
            AppLogger.error("Unexpected error pushing timer state: \(error.localizedDescription)", category: .sync)
        }
    }

    private func applyBackendStateToLocal(_ state: ApiClient.TimerStateDto) async {
        AppLogger.logSyncEvent("applying_backend_state")

        await MainActor.run {
            guard let timer = self.timer else {
                AppLogger.warning("No timer instance available for backend state application", category: .sync)
                return
            }

            // Map phase string to Phase enum
            let phase: Phase
            switch state.phase.lowercased() {
            case "work": phase = .work
            case "break": phase = .break
            case "longbreak", "long_break": phase = .longBreak
            default:
                phase = .work
                AppLogger.warning("Unknown phase '\(state.phase)', defaulting to work", category: .sync)
            }

            AppLogger.debug("Applying backend state: phase=\(phase), remaining=\(state.remainingSeconds), running=\(state.isRunning)", category: .sync)

            timer.applySyncedState(
                phase: phase,
                remainingSeconds: state.remainingSeconds,
                isRunning: state.isRunning,
                workDuration: state.workDuration,
                breakDuration: state.breakDuration,
                longBreakDuration: state.longBreakDuration,
                autoStartNextSession: state.autoStartNextSession,
                shortBreaksCompleted: state.shortBreaksCompleted
            )

            AppLogger.logSyncEvent("backend_state_applied_successfully")
        }
    }

    private func sendActionToBackend(_ action: TimerAction, timestamp: Date) {
        guard let accessToken = try? KeychainStore.loadString(.accessToken),
              let config = ApiClient.Configuration.fromInfoPlist(),
              let timer = self.timer else {
            AppLogger.warning("No access token, API config, or timer available for backend sync", category: .sync)
            return
        }

        let apiClient = ApiClient(configuration: config)

        _Concurrency.Task {
            do {
                // Get the current timer state to include with the action
                let (phase, _) = getLocalTimerStateWithTimestamp()

                let actionDto = ApiClient.TimerActionDto(
                    action: action.rawValue,
                    timestamp: timestamp,
                    deviceId: deviceId,
                    phase: phase.rawValue,
                    remainingSeconds: timer.remainingSeconds,
                    isRunning: timer.isRunning,
                    workDuration: timer.workDuration,
                    breakDuration: timer.breakDuration,
                    longBreakDuration: timer.longBreakDuration,
                    autoStartNextSession: timer.autoStartNextSession,
                    shortBreaksCompleted: timer.shortBreaksCompleted
                )

                try await apiClient.pushTimerAction(actionDto, accessToken: accessToken)
                AppLogger.debug("Successfully synced timer action with complete state to backend", category: .sync)

                // Send APN notification to other devices
                await sendApnNotification(for: action, timestamp: timestamp)

            } catch {
                AppLogger.error("Failed to sync timer action to backend: \(error.localizedDescription)", category: .sync)
            }
        }
    }

    private func sendApnNotification(for action: TimerAction, timestamp: Date) async {
        guard let accessToken = try? KeychainStore.loadString(.accessToken),
              let config = ApiClient.Configuration.fromInfoPlist() else {
            AppLogger.warning("No access token or API config available for APN notification", category: .sync)
            return
        }

        let apiClient = ApiClient(configuration: config)

        do {
            // Create APN payload for timer sync
            let timerSyncAction = ApiClient.TimerSyncAction(
                action: action.rawValue,
                deviceId: deviceId,
                timestamp: ISO8601DateFormatter().string(from: timestamp)
            )

            let apnPayload = ApiClient.ApnNotificationPayload(
                type: "timer_sync",
                action: timerSyncAction
            )

            // Send silent APN notification to other devices
            try await apiClient.sendApnNotification(payload: apnPayload, accessToken: accessToken)
            AppLogger.debug("Successfully sent APN notification for timer action: \(action.rawValue)", category: .sync)

        } catch {
            AppLogger.error("Failed to send APN notification: \(error.localizedDescription)", category: .sync)
        }
    }


}

// MARK: - Logger Extension
// extension LoggerStore {
//     static let sync = Logger(subsystem: "com.sparkage.timebeam", category: "sync")
// }
