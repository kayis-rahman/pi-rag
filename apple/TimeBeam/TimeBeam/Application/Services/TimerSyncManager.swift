import os
import SwiftUI
import Foundation

@MainActor
final class TimerSyncManager: ObservableObject {
    static let shared = TimerSyncManager()

    @Published var isSyncing: Bool = false

    var deviceId: String
    private var timer: PomodoroTimer?

    func getTimer() -> PomodoroTimer? { timer }

    // MARK: - Initialization
    private init() {
        deviceId = UUID().uuidString
    }

    func configure(with timer: PomodoroTimer) {
        self.timer = timer
    }

    // MARK: - State Sync
    func syncTimerState() async {
        guard let timer = timer else { return }
        isSyncing = true
        defer { isSyncing = false }

        do {
            guard let accessToken = try? KeychainStore.loadString(.accessToken) else {
                LoggerStore.timer.error("No access token available for sync")
                return
            }

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

            try await ApiClient.shared.pushTimerState(stateDto, accessToken: accessToken)

            // Pull latest state from backend
            if let pulledState = try await ApiClient.shared.pullTimerState(accessToken: accessToken) {
                // Apply if more recent
                if timer.lastModifiedTimestamp < pulledState.lastModifiedTimestamp {
                    // For cross-device sync, use the exact remainingSeconds from the remote state
                    // instead of trying to recalculate based on timestamps
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
        let lastModifiedTimestamp = stateDict["lastModifiedTimestamp"] as? Double ?? Date().timeIntervalSince1970

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