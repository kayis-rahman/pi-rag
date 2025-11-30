// TimeBeamWatchApp.swift
import SwiftUI
import TimeBeamShared

@main
struct TimeBeamWatchApp: App {
    @StateObject private var timer = TimeBeamShared.PomodoroTimer()
    @StateObject private var logger = SessionLogger()

    @StateObject private var authManager = AuthManager()
    @StateObject private var wcManager = WatchConnectivityManager()

    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .environmentObject(timer)
                .environmentObject(logger)
                .environmentObject(authManager)
                .environmentObject(wcManager)
                .onAppear {
                    timer.onSessionCompleted = { phase, duration in
                        let kind: SessionRecord.Kind
                        switch phase {
                        case .work: kind = .work
                        case .break: kind = .shortBreak
                        case .longBreak: kind = .longBreak
                        }
                        let start = Date().addingTimeInterval(-TimeInterval(duration))
                        let record = SessionRecord(startedAt: start, duration: TimeInterval(duration), kind: kind)
                        logger.add(record: record)
                    }
                }
        }
    }
}
