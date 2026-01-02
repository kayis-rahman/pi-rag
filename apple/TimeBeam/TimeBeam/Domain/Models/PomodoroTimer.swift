import Foundation
import os
import SwiftUI
import Combine
import _Concurrency

enum Phase: String, Codable, CaseIterable, Hashable, Identifiable, Sendable {
    case work = "work"
    case `break` = "short_break"
    case longBreak = "long_break"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .work: return "Work"
        case .break: return "Break"
        case .longBreak: return "Long Break"
        }
    }
}

@MainActor
class PomodoroTimer: ObservableObject {
    @Published var phase: Phase = .work
    @Published var remainingSeconds: Int = 25 * 60
    @Published var isRunning: Bool = false
    @Published var shortBreaksCompleted: Int = 0
    @Published var autoStartNextSession: Bool = true
    @Published var currentTaskId: UUID?

    private(set) var workDuration: Int = 25 * 60
    private(set) var breakDuration: Int = 5 * 60
    private(set) var longBreakDuration: Int = 15 * 60
    let cycleSize: Int = 4
    var onSessionCompleted: ((Phase, Int) -> Void)?

    private var timerTask: _Concurrency.Task<Void, Never>?
    var startTimestamp: Double?
    var pauseTimestamp: Double?
    var lastModifiedTimestamp: Double

    init() {
        self.workDuration = 25 * 60
        self.breakDuration = 5 * 60
        self.longBreakDuration = 15 * 60
        self.remainingSeconds = 25 * 60
        self.phase = .work
        self.isRunning = false
        self.autoStartNextSession = false
        self.shortBreaksCompleted = 0
        self.currentTaskId = nil
        self.startTimestamp = nil
        self.pauseTimestamp = nil
        self.lastModifiedTimestamp = Date().timeIntervalSince1970
    }

    deinit {
        timerTask?.cancel()
    }

    var progress: Double {
        let current = Double(currentDuration) - Double(remainingSeconds)
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

    func start() {
        guard !isRunning else { return }
        isRunning = true
        startTimestamp = Date().timeIntervalSince1970
        lastModifiedTimestamp = startTimestamp!
        startTimer()
    }

    func pause() {
        guard isRunning else { return }
        isRunning = false
        pauseTimestamp = Date().timeIntervalSince1970
        lastModifiedTimestamp = pauseTimestamp!
        stopTimer()
    }

    func reset() {
        stopTimer()
        remainingSeconds = currentDuration
        phase = .work
        isRunning = false
        shortBreaksCompleted = 0
        startTimestamp = nil
        pauseTimestamp = nil
        lastModifiedTimestamp = Date().timeIntervalSince1970
    }

    func advance() {
        let previousPhase = phase
        switch previousPhase {
        case .work:
            shortBreaksCompleted += 1
            if shortBreaksCompleted >= cycleSize {
                phase = .longBreak
                remainingSeconds = longBreakDuration
            } else {
                phase = .break
                remainingSeconds = breakDuration
            }
        case .break:
            phase = .work
            remainingSeconds = workDuration
        case .longBreak:
            phase = .work
            remainingSeconds = workDuration
        }

        lastModifiedTimestamp = Date().timeIntervalSince1970
        onSessionCompleted?(previousPhase, currentDuration)
    }

    func applySyncedState(
        phase: Phase,
        remainingSeconds: Int,
        isRunning: Bool,
        workDuration: Int,
        breakDuration: Int,
        longBreakDuration: Int,
        autoStartNextSession: Bool,
        shortBreaksCompleted: Int,
        startTimestamp: Double?,
        pauseTimestamp: Double?,
        lastModifiedTimestamp: Double
    ) {
        self.phase = phase
        self.remainingSeconds = remainingSeconds
        self.isRunning = isRunning
        self.workDuration = workDuration
        self.breakDuration = breakDuration
        self.longBreakDuration = longBreakDuration
        self.autoStartNextSession = autoStartNextSession
        self.shortBreaksCompleted = shortBreaksCompleted
        self.startTimestamp = startTimestamp
        self.pauseTimestamp = pauseTimestamp
        self.lastModifiedTimestamp = lastModifiedTimestamp
        
        if isRunning {
            startTimer()
        } else {
            stopTimer()
        }
    }

    private func startTimer() {
        stopTimer()
        timerTask = _Concurrency.Task {
            while self.isRunning && remainingSeconds > 0 {
                try? await _Concurrency.Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                await MainActor.run {
                    if self.isRunning && remainingSeconds > 0 {
                        remainingSeconds -= 1
                    }
                }
            }
        }
    }

    private func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
    }

    func updateDurations(workMinutes: Int, shortBreakMinutes: Int, longBreakMinutes: Int) {
        self.workDuration = workMinutes * 60
        self.breakDuration = shortBreakMinutes * 60
        self.longBreakDuration = longBreakMinutes * 60
        self.remainingSeconds = 25 * 60
        self.phase = .work
        self.isRunning = false
        self.autoStartNextSession = false
        self.shortBreaksCompleted = 0
        self.currentTaskId = nil
        self.startTimestamp = nil
        self.pauseTimestamp = nil
        self.lastModifiedTimestamp = Date().timeIntervalSince1970
    }

    func resetDurationsToDefaults() {
        let defaults = UserDefaults.standard
        defaults.set(workDuration / 60, forKey: "workDuration")
        defaults.set(breakDuration / 60, forKey: "breakDuration")
        defaults.set(longBreakDuration / 60, forKey: "longBreakDuration")
    }
  }


