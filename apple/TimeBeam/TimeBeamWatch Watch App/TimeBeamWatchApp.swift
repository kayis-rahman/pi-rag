//  TimeBeamWatchApp.swift
//  TimeBeamWatch Watch App
//
//  Created by automated assistant.

import SwiftUI
import TimeBeamShared

@main
struct TimeBeamWatchApp: App {
    @StateObject private var timer = PomodoroTimer()

    var body: some Scene {
        WindowGroup {
            TimeBeamShared.ContentView()
                .environmentObject(timer)
        }
    }
}
