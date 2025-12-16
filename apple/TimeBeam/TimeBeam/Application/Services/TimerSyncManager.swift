import os
import SwiftUI
import Foundation
import _Concurrency

@MainActor
final class TimerSyncManager: ObservableObject {
    static let shared = TimerSyncManager()

    @Published var isSyncing: Bool = false

    var deviceId: String
    private var timer: PomodoroTimer?
    private var queuedSyncNeeded: Bool = false

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

    // MARK: - State Sync
    func syncTimerState() async {
        print("🚀 TIMER_SYNC_START: syncTimerState() called")
        guard let timer = timer else {
            print("⚠️ TIMER_SYNC_SKIP: No timer configured yet, queuing for later")
            // Queue the sync to run when timer is configured
            queuedSyncNeeded = true
            return
        }
        await performSyncTimerState()
    }

    private func performSyncTimerState() async {
        guard let timer = timer else { return }
        isSyncing = true
        print("✅ TIMER_SYNC_ACTIVE: Starting sync process")
        defer { isSyncing = false }

        do {
            guard let accessToken = ApiClient.getValidAccessToken() else {
                LoggerStore.timer.error("No access token available for sync")
                print("❌ TIMER_SYNC: No access token available from any source")
                return
            }

            // Diagnostic logging for token loading
            print("✅ TIMER_SYNC: Access token loaded, length: \(accessToken.count)")
            print("✅ TIMER_SYNC: Token prefix: \(accessToken.prefix(20))...")

            // Push current state to backend
            let stateDto = ApiClient.TimerStateDto(
                startTimestamp: timer.startTimestamp,
                pauseTimestamp: timer.pauseTimestamp,
                totalDuration: Int(timer.currentDuration),
                remainingSeconds: Int(timer.remainingSeconds),
                phase: timer.phase.rawValue,
                isRunning: timer.isRunning,
                workDuration: timer.workDuration,
                breakDuration: timer.breakDuration,
                longBreakDuration: timer.longBreakDuration,
                autoStartNextSession: timer.autoStartNextSession,
                  shortBreaksCompleted: timer.shortBreaksCompleted,
                  lastModifiedTimestamp: timer.lastModifiedTimestamp,
                deviceId: deviceId
            )

            // Diagnostic logging for timer state being pushed
            print("📤 TIMER_SYNC_PUSH: Pushing state - phase: \(timer.phase.rawValue), remaining: \(timer.remainingSeconds), running: \(timer.isRunning), device: \(deviceId)")
            print("📤 TIMER_SYNC_PUSH: StateDto - start: \(stateDto.startTimestamp ?? 0), remaining: \(stateDto.remainingSeconds), lastModified: \(stateDto.lastModifiedTimestamp)")

            try await ApiClient.shared.pushTimerState(stateDto, accessToken: accessToken)

            // Pull latest state from backend
            if let pulledState = try await ApiClient.shared.pullTimerState(accessToken: accessToken) {
                // Diagnostic logging for pulled state
                print("📥 TIMER_SYNC_PULL: Received state - phase: \(pulledState.phase), remaining: \(pulledState.remainingSeconds), running: \(pulledState.isRunning), device: \(pulledState.deviceId)")
                print("📥 TIMER_SYNC_PULL: Pulled timestamps - start: \(pulledState.startTimestamp ?? 0), lastModified: \(pulledState.lastModifiedTimestamp)")

                // Use Date directly for comparison (already parsed by JSONDecoder)
                let currentModified = timer.lastModifiedTimestamp
                let pulledModified = pulledState.lastModifiedTimestamp

                print("📊 TIMER_SYNC_COMPARE: Current modified: \(currentModified), Pulled modified: \(pulledModified), Should sync: \(currentModified < pulledModified)")

                // Apply if more recent
                  if timer.lastModifiedTimestamp < pulledState.lastModifiedTimestamp {
                    // For cross-device sync, use the exact remainingSeconds from the remote state
                    // instead of trying to recalculate based on timestamps
                    print("✅ TIMER_SYNC_APPLY: Applying synced state to local timer")
                    timer.applySyncedState(
                        phase: Phase(rawValue: pulledState.phase) ?? .work,
                        remainingSeconds: pulledState.remainingSeconds,
                        isRunning: pulledState.isRunning,
                        workDuration: pulledState.workDuration,
                        breakDuration: pulledState.breakDuration,
                        longBreakDuration: pulledState.longBreakDuration,
                        autoStartNextSession: pulledState.autoStartNextSession,
                        shortBreaksCompleted: pulledState.shortBreaksCompleted,
                        startTimestamp: pulledState.startTimestamp,
                        pauseTimestamp: pulledState.pauseTimestamp,
                          lastModifiedTimestamp: pulledState.lastModifiedTimestamp
                    )
                    print("✅ TIMER_SYNC_APPLY: State applied successfully")
                }
            }
        } catch {
            LoggerStore.timer.error("Failed to sync timer state: \(error.localizedDescription)")
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

