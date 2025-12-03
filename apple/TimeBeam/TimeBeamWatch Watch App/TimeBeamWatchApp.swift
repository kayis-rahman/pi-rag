import SwiftUI

//  TimeBeamWatchApp.swift
//  TimeBeamWatch Watch App
//
//  Created by automated assistant.

@main
struct TimeBeamWatchApp: App {
    @StateObject private var timer = PomodoroTimer()

    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .environmentObject(timer)
        }
    }
}
