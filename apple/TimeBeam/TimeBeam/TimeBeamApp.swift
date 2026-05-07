import SwiftUI
import UserNotifications

#if os(macOS)
import AppKit
#endif

#if os(iOS)
import UIKit
#endif

// MARK: - Main App Structure

@main
struct TimeBeamApp: App {
    #if os(macOS)
    @NSApplicationDelegateAdaptor(MacAppDelegate.self) var appDelegate
    #else
    @UIApplicationDelegateAdaptor(iOSAppDelegate.self) var appDelegate
    #endif

    @StateObject var timer = PomodoroTimer()
    @StateObject var logger = SessionLogger()
    @StateObject var authManager = AuthManager.shared
    @StateObject var taskService = TaskService()
    @StateObject var analyticsManager = AnalyticsManager(
        apiClient: AnalyticsApiClient(baseURL: Configuration.fromInfoPlist()?.baseURL ?? URL(string: ProcessInfo.processInfo.environment["API_BASE_URL"] ?? "http://192.168.0.202:8080")!),
        authManager: AuthManager.shared
    )

    @State private var isAppReady = false
    @State private var selectedTab = 0
    @State private var navigationPath = NavigationPath()
    @State private var isSidebarCollapsed = false
    @State private var previousTab = 0
    @State private var transitionDirection = TransitionDirection.none

    var body: some Scene {
        WindowGroup {
            #if os(iOS)
            Group {
                if isAppReady {
                    VStack(spacing: 0) {
                        Group {
                            switch selectedTab {
                            case 0: iOSContentView()
                            case 1: TaskListView()
                            case 2: StatsView()
                            case 3: SettingsView()
                            default: iOSContentView()
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .transition(.opacity)

                        BottomTabView(selectedTab: $selectedTab)
                            .frame(height: 80)
                            .background(Color(.secondarySystemBackground))
                    }
                    .environmentObject(timer)
                    .environmentObject(logger)
                    .environmentObject(authManager)
                    .environmentObject(taskService)
                    .environmentObject(analyticsManager)
                    .accentColor(Color.themePrimary)
                } else {
                    LoadingView()
                        .onAppear {
                            Task {
                                await setupApp()
                            }
                        }
                }
            }
            #else
            Group {
                if isAppReady {
                    macOSContentView()
                        .environmentObject(timer)
                        .environmentObject(logger)
                        .environmentObject(authManager)
                        .environmentObject(taskService)
                        .environmentObject(analyticsManager)
                } else {
                    LoadingView()
                        .onAppear {
                            Task {
                                await setupApp()
                            }
                        }
                }
            }
            #endif
        }
    }

    @MainActor
    private func setupApp() async {
        // Restore auth session
        await authManager.restoreSession()

        // Pull latest timer state from backend if signed in
        if authManager.isSignedIn,
           let accessToken = authManager.getValidAccessToken() {
            do {
                let pulledState = try await ApiClient.shared.pullTimerState(accessToken: accessToken)
                if let state = pulledState {
                    let pulledModified = state.lastModifiedTimestamp?.timeIntervalSince1970 ?? 0
                    if pulledModified > 0 {
                        timer.applySyncedState(
                            phase: Phase(rawValue: state.phase ?? "work") ?? .work,
                            remainingSeconds: state.remainingSeconds ?? 0,
                            isRunning: state.isRunning ?? false,
                            workDuration: state.workDuration ?? 25,
                            breakDuration: state.breakDuration ?? 5,
                            longBreakDuration: state.longBreakDuration ?? 15,
                            autoStartNextSession: state.autoStartNextSession ?? false,
                            shortBreaksCompleted: state.shortBreaksCompleted ?? 0,
                            startTimestamp: state.startTimestamp?.timeIntervalSince1970,
                            pauseTimestamp: state.pauseTimestamp?.timeIntervalSince1970,
                            lastModifiedTimestamp: pulledModified
                        )
                        print("✅ APP_LAUNCH: Applied synced timer state from backend")
                    }
                }
            } catch {
                print("⚠️ APP_LAUNCH: Failed to pull timer state: \(error.localizedDescription)")
            }
        }

        // Configure timer sync manager
        TimerSyncManager.shared.configure(with: timer)

        isAppReady = true
    }
}

