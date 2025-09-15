//  PomodoroTimer.swift
//  TimeBeam
//
//  Created by AI Assistant on 15/09/25.

import Foundation
import SwiftUI
#if os(macOS)
import AppKit
#endif

@MainActor
final class PomodoroTimer: ObservableObject {
    enum Phase: String, Codable { case work, `break` }

    struct TimerState: Codable {
        let phase: Phase
        let remainingSeconds: Int
        let isRunning: Bool
        let lastActiveDate: Date?
    }

    // Configurable durations (in seconds)
    let workDuration: Int
    let breakDuration: Int

    // Published state
    @Published private(set) var phase: Phase = .work
    @Published private(set) var remainingSeconds: Int
    @Published private(set) var isRunning: Bool = false

    private var timerTask: Task<Void, Never>? = nil
    private let stateKey = "PomodoroTimerState"

    init(workDuration: Int = 2 * 60, breakDuration: Int = 1 * 60) {
        self.workDuration = workDuration
        self.breakDuration = breakDuration
        // Try to restore state
        if let state = PomodoroTimer.loadState() {
            self.phase = state.phase
            self.remainingSeconds = state.remainingSeconds
            self.isRunning = false // Always start paused for safety
            if let lastActive = state.lastActiveDate, state.isRunning {
                let elapsed = Int(Date().timeIntervalSince(lastActive))
                let updated = max(0, state.remainingSeconds - elapsed)
                self.remainingSeconds = updated
                // If time ran out while app was closed, switch phase
                if updated == 0 {
                    self.switchPhase()
                }
            }
        } else {
            self.phase = .work
            self.remainingSeconds = workDuration
            self.isRunning = false
        }
        // Removed updateDockBadge() and updateStatusItem() from here
    }

    deinit {
        timerTask?.cancel()
    }

    // Current phase total duration
    var currentDuration: Int { phase == .work ? workDuration : breakDuration }

    // 0.0 -> just started, 1.0 -> phase ended
    var progress: Double {
        guard currentDuration > 0 else { return 0 }
        let p = 1.0 - (Double(remainingSeconds) / Double(currentDuration))
        return min(max(p, 0), 1)
    }

    func start() {
        print("[PomodoroTimer] start() called. isRunning: \(isRunning)")
        guard !isRunning else { return }
        isRunning = true
        saveState()
        updateDockBadge()
        updateStatusItem()
        timerTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled, self.isRunning {
                do { try await Task.sleep(for: .seconds(1)) } catch { break }
                tick()
            }
        }
    }

    func pause() {
        guard isRunning else { return }
        isRunning = false
        timerTask?.cancel()
        timerTask = nil
        saveState()
        updateDockBadge()
        updateStatusItem()
    }

    func reset() {
        pause()
        phase = .work
        remainingSeconds = workDuration
        saveState()
        updateDockBadge()
        updateStatusItem()
    }

    private func tick() {
        print("[PomodoroTimer] tick() called. remainingSeconds: \(remainingSeconds)")
        guard isRunning else { return }
        if remainingSeconds > 0 {
            remainingSeconds -= 1
            saveState()
            updateDockBadge()
            updateStatusItem()
        }
        if remainingSeconds == 0 {
            switchPhase()
        }
    }

    private func switchPhase() {
        let completedPhase = phase
        if phase == .work {
            phase = .break
            remainingSeconds = breakDuration
        } else {
            phase = .work
            remainingSeconds = workDuration
        }
        saveState()
        updateDockBadge()
        updateStatusItem()
        // Trigger notification when phase completes
        NotificationManager.shared.sendSessionDoneNotification(phase: completedPhase.rawValue)
    }

    private func updateDockBadge() {
        #if os(macOS)
        DispatchQueue.main.async {
            if self.isRunning {
                let minutes = self.remainingSeconds / 60
                let seconds = self.remainingSeconds % 60
                let badge = String(format: "%d:%02d", minutes, seconds)
                NSApplication.shared.dockTile.badgeLabel = badge
            } else {
                NSApplication.shared.dockTile.badgeLabel = nil
            }
        }
        #endif
    }

    private func updateStatusItem() {
        #if os(macOS)
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        let title = String(format: "%d:%02d", minutes, seconds)
        print("[PomodoroTimer] updateStatusItem() called. title: \(title)")
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            print("[PomodoroTimer] AppDelegate found. Calling updateStatusItem.")
            type(of: appDelegate).updateStatusItem(title: title)
        } else {
            print("[PomodoroTimer] AppDelegate NOT found.")
        }
        #endif
    }

    private func saveState() {
        let state = TimerState(
            phase: phase,
            remainingSeconds: remainingSeconds,
            isRunning: isRunning,
            lastActiveDate: isRunning ? Date() : nil
        )
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: stateKey)
        }
    }

    private static func loadState() -> TimerState? {
        guard let data = UserDefaults.standard.data(forKey: "PomodoroTimerState") else { return nil }
        return try? JSONDecoder().decode(TimerState.self, from: data)
    }
}

extension PomodoroTimer.Phase {
    var displayName: String {
        switch self {
        case .work: return "Work"
        case .break: return "Break"
        }
    }
}

extension Int {
    var mmss: String {
        let minutes = self / 60
        let seconds = self % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
