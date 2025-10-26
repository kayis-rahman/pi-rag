//  PomodoroTimer.swift
//  TimeBeamShared
//
//  Shared Pomodoro timer used by UI across platforms.

import Foundation
import SwiftUI
#if os(macOS)
import AppKit
#endif

@MainActor
public final class PomodoroTimer: ObservableObject {
    public enum Phase: String, Codable { case work, `break`, longBreak }

    public struct TimerState: Codable {
        public let phase: Phase
        public let remainingSeconds: Int
        public let isRunning: Bool
        public let lastActiveDate: Date?
        public let shortBreaksCompleted: Int
    }
    
    // Default durations (in seconds)
    private static let defaultWorkDuration = 1 * 60
    private static let defaultBreakDuration = 2 * 60
    private static let defaultLongBreakDuration = 3 * 60

    // Configurable durations (in seconds)
    @Published public var workDuration: Int
    @Published public var breakDuration: Int
    @Published public var longBreakDuration: Int
    public let cycleSize: Int = 4

    // Published state
    @Published public private(set) var phase: Phase
    @Published public private(set) var remainingSeconds: Int
    @Published public private(set) var isRunning: Bool
    @Published public private(set) var shortBreaksCompleted: Int // 0...cycleSize
    @Published public var autoStartNextSession: Bool {
        didSet {
            UserDefaults.standard.set(autoStartNextSession, forKey: autoStartNextSessionKey)
        }
    }

    public var onSessionCompleted: ((Phase, Int) -> Void)? = nil

    private var timerTask: Task<Void, Never>? = nil
    private let stateKey = "PomodoroTimerState"
    private let workDurationKey = "workDurationKey"
    private let breakDurationKey = "breakDurationKey"
    private let longBreakDurationKey = "longBreakDurationKey"
    private let autoStartNextSessionKey = "autoStartNextSessionKey"

    public init() {
        // Phase 1: Initialize all stored properties from the class.
        // Load custom durations or use defaults. We need to load workDuration into a
        // local variable first, because self is not available until all stored
        // properties are initialized.
        let workDuration = UserDefaults.standard.object(forKey: workDurationKey) as? Int ?? PomodoroTimer.defaultWorkDuration
        self.workDuration = workDuration
        self.breakDuration = UserDefaults.standard.object(forKey: breakDurationKey) as? Int ?? PomodoroTimer.defaultBreakDuration
        self.longBreakDuration = UserDefaults.standard.object(forKey: longBreakDurationKey) as? Int ?? PomodoroTimer.defaultLongBreakDuration
        
        // Initialize state properties with default values.
        self.phase = .work
        self.isRunning = false
        self.shortBreaksCompleted = 0
        self.remainingSeconds = workDuration
        self.autoStartNextSession = UserDefaults.standard.bool(forKey: autoStartNextSessionKey)
        
        // Phase 2: Now we can use `self` freely to modify properties or call methods.
        // Try to restore state and overwrite the defaults.
        if let state = PomodoroTimer.loadState() {
            self.phase = state.phase
            self.remainingSeconds = state.remainingSeconds
            self.shortBreaksCompleted = min(max(state.shortBreaksCompleted, 0), cycleSize)
            
            // Adjust for time elapsed since last active
            if let lastActive = state.lastActiveDate, state.isRunning {
                let elapsed = Int(Date().timeIntervalSince(lastActive))
                let updated = max(0, self.remainingSeconds - elapsed)
                self.remainingSeconds = updated
                if updated == 0 {
                    // This method call is now safe because initialization is complete.
                    self.switchPhase(logSession: false) // Don't log a session that finished in the background
                }
            }
        }
    }

    deinit {
        timerTask?.cancel()
    }

    // Current phase total duration
    public var currentDuration: Int {
        switch phase {
        case .work: return workDuration
        case .break: return breakDuration
        case .longBreak: return longBreakDuration
        }
    }

    // 0.0 -> just started, 1.0 -> phase ended
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
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                if let strongSelf = self {
                    await strongSelf.tick() // Tick first for immediate update
                    // Use nanoseconds for broader platform compatibility
                    do { try await Task.sleep(nanoseconds: 1_000_000_000) } catch { break }
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
    }

    public func reset() {
        pause()
        phase = .work
        remainingSeconds = workDuration
        shortBreaksCompleted = 0
        saveState()
        updateDockBadge()
        updateStatusItem()
    }
    
    public func updateDurations(workMinutes: Int, shortBreakMinutes: Int, longBreakMinutes: Int) {
        let wasRunning = isRunning
        if wasRunning { pause() }
        
        self.workDuration = workMinutes * 60
        self.breakDuration = shortBreakMinutes * 60
        self.longBreakDuration = longBreakMinutes * 60
        
        UserDefaults.standard.set(self.workDuration, forKey: workDurationKey)
        UserDefaults.standard.set(self.breakDuration, forKey: breakDurationKey)
        UserDefaults.standard.set(self.longBreakDuration, forKey: longBreakDurationKey)
        
        // If timer was paused, update remaining seconds to new duration for the current phase
        if !wasRunning {
            self.remainingSeconds = currentDuration
        }
        
        saveState()
        updateDockBadge()
        updateStatusItem()
        
        if wasRunning { start() }
    }
    
    public func resetDurationsToDefaults() {
        updateDurations(
            workMinutes: PomodoroTimer.defaultWorkDuration / 60,
            shortBreakMinutes: PomodoroTimer.defaultBreakDuration / 60,
            longBreakMinutes: PomodoroTimer.defaultLongBreakDuration / 60
        )
        reset() // Also reset the timer state
    }

    public func tick() {
        guard isRunning else { return }
        if remainingSeconds > 0 {
            remainingSeconds -= 1
        }
        if remainingSeconds == 0 {
            switchPhase(logSession: true)
        }
        saveState()
        updateDockBadge()
        updateStatusItem()
    }

    private func switchPhase(logSession: Bool) {
        let completedPhase = phase
        let completedDuration = currentDuration
        
        if logSession {
            onSessionCompleted?(completedPhase, completedDuration)
        }
        
        if phase == .work {
            if shortBreaksCompleted + 1 >= cycleSize {
                phase = .longBreak
                remainingSeconds = longBreakDuration
                shortBreaksCompleted = 0
            } else {
                phase = .break
                remainingSeconds = breakDuration
                shortBreaksCompleted += 1
            }
        } else {
            phase = .work
            remainingSeconds = workDuration
        }

        if !autoStartNextSession {
            pause()
        }

        saveState()
        updateDockBadge()
        updateStatusItem()
        NotificationManager.shared.sendSessionDoneNotification(phase: completedPhase.rawValue)
    }
    
    // Platform hooks (no app-specific references)
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
        // Intentionally left as a no-op in shared code.
        // App targets can observe timer changes and update status items themselves.
    }

    // Persistence
    private func saveState() {
        let state = TimerState(
            phase: phase,
            remainingSeconds: remainingSeconds,
            isRunning: isRunning,
            lastActiveDate: isRunning ? Date() : nil,
            shortBreaksCompleted: shortBreaksCompleted
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
        case .longBreak: return "Long Break"
        }
    }
}
