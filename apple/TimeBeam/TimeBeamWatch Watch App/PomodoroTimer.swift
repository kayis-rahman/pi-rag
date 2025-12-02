import Foundation
import SwiftUI

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
