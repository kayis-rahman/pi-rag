//  TimeBeamWatchApp.swift
//  TimeBeamWatch Watch App
//
//  Created by automated assistant.

import SwiftUI

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
