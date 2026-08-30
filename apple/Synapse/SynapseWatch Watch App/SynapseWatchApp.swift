import SwiftUI

//  SynapseWatchApp.swift
//  SynapseWatch Watch App
//
//  Created by automated assistant.

@main
struct SynapseWatchApp: App {
    @StateObject private var timer = PomodoroTimer()

    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .environmentObject(timer)
        }
    }
}
