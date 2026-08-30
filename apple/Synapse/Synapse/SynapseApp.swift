import SwiftUI
import Observation
import SwiftData
import UserNotifications

#if os(macOS)
import AppKit
#endif

#if os(iOS)
import UIKit
#endif

// MARK: - Main App Structure

@main
struct SynapseApp: App {
    #if os(macOS)
    @NSApplicationDelegateAdaptor(MacAppDelegate.self) var appDelegate
    #else
    @UIApplicationDelegateAdaptor(iOSAppDelegate.self) var appDelegate
    #endif

    @State var timer = PomodoroTimer()
    @State var logger = SessionLogger()
    @State var authManager = AuthManager.shared
    @State var taskService = TaskService()
    @State var analyticsManager = AnalyticsManager(
        apiClient: AnalyticsApiClient(baseURL: Configuration.fromInfoPlist()?.baseURL ?? URL(string: ProcessInfo.processInfo.environment["API_BASE_URL"] ?? "http://192.168.0.202:8080")!),
        authManager: AuthManager.shared
    )
    @State var syncAlertManager = SyncFailureAlertManager.shared
    @State var featureFlags = FeatureFlags.shared

    @State private var isAppReady = false

    var body: some Scene {
        WindowGroup {
            #if os(iOS)
            Group {
                if isAppReady {
                    VStack(spacing: 0) {
                        SyncStatusBanner(alertManager: syncAlertManager)

                        GTDWorkspaceView()
                    }
                    .environment(timer)
                    .environment(logger)
                    .environment(authManager)
                    .environment(taskService)
                    .environment(analyticsManager)
                    .environment(syncAlertManager)
                    .environment(featureFlags)
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
                    VStack(spacing: 0) {
                        SyncStatusBanner(alertManager: syncAlertManager)

                        macOSContentView()
                    }
                    .environment(timer)
                    .environment(logger)
                    .environment(authManager)
                    .environment(taskService)
                    .environment(analyticsManager)
                    .environment(syncAlertManager)
                    .environment(featureFlags)
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
        .modelContainer(SynapseModelContainer.shared)
    }

    @MainActor
    private func setupApp() async {
        let processInfo = ProcessInfo.processInfo
        if processInfo.arguments.contains("-ui-testing") ||
            processInfo.environment["SYNAPSE_UI_TESTING"] == "1" {
            try? GTDWorkspaceUITestData.seedProjectsAndAreasIfRequested(
                in: ModelContext(SynapseModelContainer.shared)
            )
            isAppReady = true
            WeeklyReviewReminderService.shared.schedule()
            return
        }

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
        TimerSyncManager.shared.configure(with: timer, accessToken: authManager.getValidAccessToken())

        // Cache remote rollout changes for the next launch. The active flag
        // snapshot remains stable for the duration of this session.
        await featureFlags.refreshRemoteConfiguration()

        isAppReady = true
        UserDefaults.standard.set(true, forKey: SynapseModelContainer.appSetupCompletedKey)
        WeeklyReviewReminderService.shared.schedule()
    }
}
