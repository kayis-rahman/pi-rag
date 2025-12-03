import Foundation
import SwiftUI

// Shared Phase enum for watchOS target

enum Phase: String, Codable, CaseIterable, Hashable, Identifiable, Sendable {
    case work
    case break
    case longBreak

    var id: Self { self }

    var displayName: String {
        switch self {
        case .work: return "Focus"
        case .break: return "Break"
        case .longBreak: return "Long Break"
        }
    }
}

@MainActor
class PomodoroTimer: ObservableObject {
    @Published private(set) var phase: Phase = .work
    @Published private(set) var remainingSeconds: Int
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var shortBreaksCompleted: Int = 0
    @Published var autoStartNextSession: Bool = true

    let cycleSize: Int = 4

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

    private var workDuration: Int = 25 * 60
    private var breakDuration: Int = 5 * 60
    private var longBreakDuration: Int = 15 * 60
    private var timerTask: Task<Void, Never>? = nil

    init() {
        self.remainingSeconds = self.workDuration
    }

    deinit {
        timerTask?.cancel()
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true

        timerTask = Task {
            while !Task.isCancelled {
                do { try await Task.sleep(for: .seconds(1)) } catch { break }
                guard self.isRunning else { break }
                self.remainingSeconds -= 1
                if self.remainingSeconds <= 0 {
                    self.advanceToNextPhase(autoStart: self.autoStartNextSession)
                }
            }
        }
    }

    func pause() {
        guard isRunning else { return }
        isRunning = false
        timerTask?.cancel()
        timerTask = nil
    }

    func reset() {
        pause()
        remainingSeconds = currentDuration
    }

    func updateDurations(workMinutes: Int, shortBreakMinutes: Int, longBreakMinutes: Int) {
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
        if wasRunning { start() }
    }

    // MARK: - Sync Methods
    func applySyncedState(phase: Phase, remainingSeconds: Int, isRunning: Bool,
                         workDuration: Int, breakDuration: Int, longBreakDuration: Int,
                         autoStartNextSession: Bool, shortBreaksCompleted: Int) {
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

        // Handle running state
        if isRunning && !wasRunning {
            start()
        } else if !isRunning && wasRunning {
            // Already paused above
        }
    }

    private func advanceToNextPhase(autoStart: Bool) {
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
        if autoStart {
            // Continue running
        } else {
            self.pause()
        }
    }
}

// MARK: - Extensions
extension Int {
    var mmss: String {
        let minutes = self / 60
        let seconds = self % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
