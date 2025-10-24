import SwiftUI
import TimeBeamShared

@main
struct TimeBeamWatchApp: App {
    @StateObject private var timer = TimeBeamShared.PomodoroTimer()

    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .environmentObject(timer)
        }
    }
}
