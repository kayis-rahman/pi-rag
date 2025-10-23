//  PomodoroTimer.swift
//  TimeBeamShared
//  Shared logic for macOS, iOS, watchOS

import Foundation
import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

@MainActor
public class PomodoroTimer: ObservableObject {
    public enum Phase: String, Codable { case work, `break` }

    public struct TimerState: Codable {
        public let phase: Phase
        public let remainingSeconds: Int
        public let isRunning: Bool
        public let lastActiveDate: Date?
    }

    public let workDuration: Int
    public let breakDuration: Int

    @Published public private(set) var phase: Phase = .work
    @Published public private(set) var remainingSeconds: Int
    @Published public private(set) var isRunning: Bool = false

    private var timerTask: Task<Void, Never>? = nil
    private let stateKey = "PomodoroTimerState"

    public init(workDuration: Int = 2 * 60, breakDuration: Int = 1 * 60) {
        self.workDuration = workDuration
        self.breakDuration = breakDuration
        if let state = PomodoroTimer.loadState() {
            self.phase = state.phase
            self.remainingSeconds = state.remainingSeconds
            self.isRunning = false
            if let lastActive = state.lastActiveDate, state.isRunning {
                let elapsed = Int(Date().timeIntervalSince(lastActive))
                let updated = max(0, state.remainingSeconds - elapsed)
                self.remainingSeconds = updated
                if updated == 0 {
                    self.switchPhase()
                }
            }
        } else {
            self.phase = .work
            self.remainingSeconds = workDuration
            self.isRunning = false
        }
        // Removed backend session sync for tests
        // SessionAPI.checkActiveSession { [weak self] active in
        //     guard let self = self else { return }
        //     DispatchQueue.main.async {
        //         self.isRunning = active
        //     }
        // }
    }

    deinit { timerTask?.cancel() }

    public var currentDuration: Int { phase == .work ? workDuration : breakDuration }
    public var progress: Double {
        guard currentDuration > 0 else { return 0 }
        let p = 1.0 - (Double(remainingSeconds) / Double(currentDuration))
        return min(max(p, 0), 1)
    }

    public func start() {
        guard !isRunning else { return }
        isRunning = true
        saveState()
        updateDockBadge()
        updateStatusItem()
        // Removed backend call: SessionAPI.startSession()
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                do { try await Task.sleep(for: .seconds(1)) } catch { break }
                if let strongSelf = self {
                    await strongSelf.tick()
                    let running = await strongSelf.isRunning
                    if !running { break }
                } else {
                    break
                }
            }
        }
    }

    public func pause() {
        guard isRunning else { return }
        isRunning = false
        timerTask?.cancel()
        timerTask = nil
        saveState()
        updateDockBadge()
        updateStatusItem()
        // Removed backend call: SessionAPI.stopSession()
    }

    public func reset() {
        pause()
        phase = .work
        remainingSeconds = workDuration
        saveState()
        updateDockBadge()
        updateStatusItem()
        // Removed backend call: SessionAPI.stopSession()
    }

    public func tick() {
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
        // NotificationManager.shared.sendSessionDoneNotification(phase: completedPhase.rawValue)
    }

    public func updateDockBadge() {
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

    public func updateStatusItem() {
        #if os(macOS)
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        let title = String(format: "%d:%02d", minutes, seconds)
        // AppDelegate.shared is app-specific; consider protocol abstraction for menu bar updates
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

public extension PomodoroTimer.Phase {
    var displayName: String {
        switch self {
        case .work: return "Work"
        case .break: return "Break"
        }
    }
}

public extension Int {
    var mmss: String {
        let minutes = self / 60
        let seconds = self % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
