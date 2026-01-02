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
        apiClient: AnalyticsApiClient(baseURL: Configuration.fromInfoPlist()?.baseURL ?? URL(string: ProcessInfo.processInfo.environment["API_BASE_URL"] ?? "http://192.168.0.173:8080")!),
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
                    NavigationView {
                        VStack(spacing: 0) {
                            mainContentView
                                .transition(.opacity)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

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
                    .navigationViewStyle(.stack)
                } else {
                    LoadingView()
                        .onAppear {
                            Concurrency.Task {
                                await setupApp()
                            }
                        }
                }
            }
            #else
            macOSContentView()
                .environmentObject(timer)
                .environmentObject(logger)
                .environmentObject(authManager)
                .environmentObject(taskService)
                .environmentObject(analyticsManager)
            #endif
        }
    }

    @MainActor
    private func setupApp() async {
        isAppReady = true
    }
}

