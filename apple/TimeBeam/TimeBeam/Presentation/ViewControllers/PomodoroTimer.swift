import Foundation
import os

import SwiftUI

@MainActor
class PomodoroTimer: ObservableObject {
    // Phase is now imported from Phase.swift

    struct TimerState: Codable {
        let phase: Phase
        let remainingSeconds: Int
        let isRunning: Bool
        let lastActiveDate: Date?
        let workDuration: Int
        let breakDuration: Int
        let longBreakDuration: Int
        let autoStartNextSession: Bool
        let shortBreaksCompleted: Int
        let backendSessionId: UUID?
        let currentTaskId: UUID?
        let lastModifiedTimestamp: Date  // When this state was last modified

        // Custom decoder for backward compatibility
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            phase = try container.decode(Phase.self, forKey: .phase)
            remainingSeconds = try container.decode(Int.self, forKey: .remainingSeconds)
            isRunning = try container.decode(Bool.self, forKey: .isRunning)
            lastActiveDate = try container.decodeIfPresent(Date.self, forKey: .lastActiveDate)
            workDuration = try container.decode(Int.self, forKey: .workDuration)
            breakDuration = try container.decode(Int.self, forKey: .breakDuration)
            longBreakDuration = try container.decode(Int.self, forKey: .longBreakDuration)
            autoStartNextSession = try container.decode(Bool.self, forKey: .autoStartNextSession)
            shortBreaksCompleted = try container.decode(Int.self, forKey: .shortBreaksCompleted)
            backendSessionId = try container.decodeIfPresent(UUID.self, forKey: .backendSessionId)
            currentTaskId = try container.decodeIfPresent(UUID.self, forKey: .currentTaskId)

            // For backward compatibility, use current date if timestamp not present
            lastModifiedTimestamp = try container.decodeIfPresent(Date.self, forKey: .lastModifiedTimestamp) ?? Date()
        }

        // Memberwise initializer for creating new instances
        init(phase: Phase, remainingSeconds: Int, isRunning: Bool, lastActiveDate: Date?, workDuration: Int, breakDuration: Int, longBreakDuration: Int, autoStartNextSession: Bool, shortBreaksCompleted: Int, backendSessionId: UUID?, currentTaskId: UUID?, lastModifiedTimestamp: Date) {
            self.phase = phase
            self.remainingSeconds = remainingSeconds
            self.isRunning = isRunning
            self.lastActiveDate = lastActiveDate
            self.workDuration = workDuration
            self.breakDuration = breakDuration
            self.longBreakDuration = longBreakDuration
            self.autoStartNextSession = autoStartNextSession
            self.shortBreaksCompleted = shortBreaksCompleted
            self.backendSessionId = backendSessionId
            self.currentTaskId = currentTaskId
            self.lastModifiedTimestamp = lastModifiedTimestamp
        }
    }

    @Published private(set) var phase: Phase = .work
    @Published private(set) var remainingSeconds: Int
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var shortBreaksCompleted: Int = 0
    @Published var autoStartNextSession: Bool = true
    @Published private(set) var currentTaskId: UUID?

    private(set) var backendSessionId: UUID?
    private var sessionToken: String? {
        (try? KeychainStore.loadString(.accessToken))
    }

    private(set) var workDuration: Int
    private(set) var breakDuration: Int
    private(set) var longBreakDuration: Int
    let cycleSize: Int = 4
    var onSessionCompleted: ((Phase, Int) -> Void)?

    var progress: Double {
        let current = Double(currentDuration - remainingSeconds)
        let total = Double(currentDuration)
        return total > 0 ? current / total : 0
    }

    var currentDuration: Int {
        switch phase {
        case .work: return workDuration
        case .break: return breakDuration
        case .longBreak: return longBreakDuration
        }
    }

    private var timerTask: _Concurrency.Task<Void, Never>? = nil
    private let stateKey = "PomodoroTimerState.v2"

    init() {
        self.workDuration = 25 * 60
        self.breakDuration = 5 * 60
        self.longBreakDuration = 15 * 60
        self.remainingSeconds = self.workDuration

        LoggerStore.timer.info("Timer initialized")

        if let state = loadState() {
            self.phase = state.phase
            self.remainingSeconds = state.remainingSeconds
            self.isRunning = false
            self.workDuration = state.workDuration
            self.breakDuration = state.breakDuration
            self.longBreakDuration = state.longBreakDuration
            self.autoStartNextSession = state.autoStartNextSession
            self.shortBreaksCompleted = state.shortBreaksCompleted
            self.backendSessionId = state.backendSessionId
            self.currentTaskId = state.currentTaskId
            LoggerStore.timer.debug("Loaded timer state: phase=\(self.phase.rawValue), backendSessionId=\(String(describing: self.backendSessionId)), currentTaskId=\(String(describing: self.currentTaskId))")
            if let lastActive = state.lastActiveDate, state.isRunning {
                let elapsed = Int(Date().timeIntervalSince(lastActive))
                let updated = max(0, state.remainingSeconds - elapsed)
                self.remainingSeconds = updated
                LoggerStore.timer.debug("Resuming timer, elapsed seconds: \(elapsed), updated remaining: \(updated)")
                if updated == 0 {
                    self.advanceToNextPhase(autoStart: false)
                }
            }
        } else {
            self.remainingSeconds = self.workDuration
            LoggerStore.timer.debug("Using default durations")
        }
    }

    deinit {
        timerTask?.cancel()
        LoggerStore.timer.info("Timer deinitialized")
    }

    // MARK: - Public Methods
    func start() {
        guard !isRunning else { LoggerStore.timer.debug("start() called but timer already running"); return }
        isRunning = true
        saveState()
        updatePlatformUI()

        LoggerStore.timer.info("Starting timer phase \(self.phase.rawValue)")

        // Sync timer start action
        TimerSyncManager.shared.syncAction(.start)

        _Concurrency.Task {
            await self.startBackendSessionIfNeeded()
        }

        timerTask = _Concurrency.Task {
            while !_Concurrency.Task.isCancelled {
                do { try await _Concurrency.Task.sleep(for: .seconds(1)) } catch { break }
                guard self.isRunning else { LoggerStore.timer.debug("Timer paused, task exiting"); break }
                self.remainingSeconds -= 1
                self.updatePlatformUI()
                if self.remainingSeconds <= 0 {
                    LoggerStore.timer.info("Timer reached zero, advancing phase")
                    self.advanceToNextPhase(autoStart: self.autoStartNextSession)
                }
                self.saveState()
            }
        }
    }

    func pause() {
        guard isRunning else { LoggerStore.timer.debug("pause() called but timer not running"); return }
        isRunning = false
        timerTask?.cancel()
        timerTask = nil
        saveState()
        updatePlatformUI()

        // Sync timer pause action
        TimerSyncManager.shared.syncAction(.pause)

        LoggerStore.timer.info("Pausing timer")
    }

    func stop() {
        LoggerStore.timer.info("Stopping timer and advancing to next phase")
        pause()
        advanceToNextPhase(autoStart: false)

        // Note: pause() already sent sync event, no need for additional stop event
    }

    func reset() {
        LoggerStore.timer.info("Resetting timer")
        pause()
        remainingSeconds = currentDuration
        _Concurrency.Task {
            await self.stopBackendSessionIfNeeded()
        }
        backendSessionId = nil
        currentTaskId = nil
        saveState()
        updatePlatformUI()

        // Sync timer reset action
        TimerSyncManager.shared.syncAction(.reset)
    }

    // MARK: - Duration Helpers
    func resetDurationsToDefaults() {
        LoggerStore.timer.info("Resetting durations to defaults")
        updateDurations(workMinutes: 25, shortBreakMinutes: 5, longBreakMinutes: 15)
    }

    func updateDurations(workMinutes: Int, shortBreakMinutes: Int, longBreakMinutes: Int) {
        LoggerStore.timer.info("Updating durations: work=\(workMinutes)m, short=\(shortBreakMinutes)m, long=\(longBreakMinutes)m")
        let wasRunning = isRunning
        pause()
        workDuration = workMinutes * 60
        breakDuration = shortBreakMinutes * 60
        longBreakDuration = longBreakMinutes * 60
        switch phase {
        case .work:
            remainingSeconds = workDuration
        case .break:
            remainingSeconds = breakDuration
        case .longBreak:
            remainingSeconds = longBreakDuration
        }
        saveState()
        if wasRunning { start() }
    }

    func setCurrentTask(_ taskId: UUID?) {
        LoggerStore.timer.info("Setting current task: \(String(describing: taskId))")
        self.currentTaskId = taskId
        saveState()
    }

    // MARK: - Sync Methods
    func applySyncedState(phase: Phase, remainingSeconds: Int, isRunning: Bool,
                          workDuration: Int, breakDuration: Int, longBreakDuration: Int,
                          autoStartNextSession: Bool, shortBreaksCompleted: Int, currentTaskId: UUID? = nil) {
        LoggerStore.timer.info("Applying synced timer state: phase=\(phase.rawValue), remaining=\(remainingSeconds), running=\(isRunning), currentTaskId=\(String(describing: currentTaskId))")

        let wasRunning = self.isRunning
        if wasRunning {
            pause() // Stop current timer
        }

        // Apply synced state
        self.phase = phase
        self.remainingSeconds = remainingSeconds
        self.workDuration = workDuration
        self.breakDuration = breakDuration
        self.longBreakDuration = longBreakDuration
        self.autoStartNextSession = autoStartNextSession
        self.shortBreaksCompleted = shortBreaksCompleted
        self.currentTaskId = currentTaskId

        // Handle running state
        if isRunning && !wasRunning {
            start()
        } else if !isRunning && wasRunning {
            // Already paused above
        }

        saveState()
        updatePlatformUI()
    }

    func applyReadOnlyState(phase: Phase, remainingSeconds: Int, isRunning: Bool,
                            workDuration: Int, breakDuration: Int, longBreakDuration: Int,
                            autoStartNextSession: Bool, shortBreaksCompleted: Int, currentTaskId: UUID? = nil) {
        LoggerStore.timer.info("Applying read-only timer state (controlled by another device): phase=\(phase.rawValue), remaining=\(remainingSeconds), running=\(isRunning), currentTaskId=\(String(describing: currentTaskId))")

        let wasRunning = self.isRunning
        if wasRunning {
            pause() // Stop current timer - we don't control it anymore
        }

        // Apply backend state as read-only
        self.phase = phase
        self.remainingSeconds = remainingSeconds
        self.workDuration = workDuration
        self.breakDuration = breakDuration
        self.longBreakDuration = longBreakDuration
        self.autoStartNextSession = autoStartNextSession
        self.shortBreaksCompleted = shortBreaksCompleted
        self.currentTaskId = currentTaskId

        // Don't start the timer even if backend says it's running - we don't control it
        // The UI should show this as read-only

        saveState()
        updatePlatformUI()
    }

    // MARK: - Backend session sync
    private func startBackendSessionIfNeeded() async {
        guard self.backendSessionId == nil else {
            LoggerStore.session.debug("Not starting backend session: already exists id=\(self.backendSessionId!.uuidString, privacy: .public)")
            return
        }
        guard let token = self.sessionToken, !token.isEmpty,
              let cfg = ApiClient.Configuration.fromInfoPlist() else {
            LoggerStore.session.error("Cannot start backend session: missing token or config")
            return
        }
        let api = ApiClient(configuration: cfg)
        let kind: ApiClient.SessionKind
        switch self.phase {
        case .work: kind = .work
        case .break: kind = .shortBreak
        case .longBreak: kind = .longBreak
        }
        do {
            LoggerStore.session.info("Calling backend startSession kind=\(kind.rawValue, privacy: .public), taskId=\(String(describing: self.currentTaskId))")
            let session = try await api.startSession(kind: kind, taskId: self.currentTaskId, accessToken: token)
            self.backendSessionId = session.id
            LoggerStore.session.info("Started backend session id=\(session.id.uuidString, privacy: .public)")
            self.saveState()
        } catch {
            LoggerStore.session.error("Failed to start backend session: \(String(describing: error), privacy: .public)")
        }
    }

    private func stopBackendSessionIfNeeded() async {
        guard let sessionId = self.backendSessionId else {
            LoggerStore.session.debug("Not stopping backend session: no active sessionId")
            return
        }
        guard let token = self.sessionToken, !token.isEmpty,
              let cfg = ApiClient.Configuration.fromInfoPlist() else {
            LoggerStore.session.error("Cannot stop backend session: missing token or config")
            return
        }
        let api = ApiClient(configuration: cfg)
        do {
            LoggerStore.session.info("Calling backend stopSession for id=\(sessionId.uuidString, privacy: .public)")
            _ = try await api.stopSession(id: sessionId, accessToken: token)
            LoggerStore.session.info("Stopped backend session id=\(sessionId.uuidString, privacy: .public)")
            self.backendSessionId = nil
            self.saveState()
        } catch {
            LoggerStore.session.error("Failed to stop backend session: \(String(describing: error), privacy: .public)")
        }
    }

    // MARK: - Private Methods

    private func advanceToNextPhase(autoStart: Bool) {
        self.onSessionCompleted?(self.phase, self.currentDuration)
        NotificationManager.shared.sendSessionDoneNotification(phase: self.phase.rawValue)

        LoggerStore.timer.info("Advancing phase from \(self.phase.rawValue) (autoStart: \(autoStart))")
        _Concurrency.Task {
            await self.stopBackendSessionIfNeeded()
        }

        let previousPhase = self.phase
        switch previousPhase {
        case .work:
            self.shortBreaksCompleted += 1
            if self.shortBreaksCompleted >= self.cycleSize {
                self.phase = .longBreak
                self.remainingSeconds = self.longBreakDuration
            } else {
                self.phase = .break
                self.remainingSeconds = self.breakDuration
            }
        case .break, .longBreak:
            if previousPhase == .longBreak {
                self.shortBreaksCompleted = 0
            }
            self.phase = .work
            self.remainingSeconds = self.workDuration
        }
        self.backendSessionId = nil
        if autoStart {
            // Already running, state will be saved by timer loop
        } else {
            self.pause()
        }
        self.saveState()
        self.updatePlatformUI()
    }

    private func updatePlatformUI() {
        #if os(macOS)
        let badgeLabel = isRunning ? remainingSeconds.mmss : nil
        NSApplication.shared.dockTile.badgeLabel = badgeLabel
        MacAppDelegate.updateStatusItem(title: badgeLabel)
        #endif
    }

    private func saveState() {
        let state = TimerState(
            phase: self.phase,
            remainingSeconds: self.remainingSeconds,
            isRunning: self.isRunning,
            lastActiveDate: self.isRunning ? Date() : nil,
            workDuration: self.workDuration,
            breakDuration: self.breakDuration,
            longBreakDuration: self.longBreakDuration,
            autoStartNextSession: self.autoStartNextSession,
            shortBreaksCompleted: self.shortBreaksCompleted,
            backendSessionId: self.backendSessionId,
            currentTaskId: self.currentTaskId,
            lastModifiedTimestamp: Date()  // Always update timestamp when saving
        )
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: self.stateKey)
        }
    }

    private func loadState() -> TimerState? {
        guard let data = UserDefaults.standard.data(forKey: self.stateKey) else { return nil }
        return try? JSONDecoder().decode(TimerState.self, from: data)
    }
}
