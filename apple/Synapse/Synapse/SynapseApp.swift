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
    @State var featureFlags = FeatureFlags.shared

    @State private var isAppReady = false

    var body: some Scene {
        WindowGroup {
            #if os(iOS)
            Group {
                if isAppReady {
                    WorkspaceView()
                    .preferredColorScheme(AppTheme(rawValue: UserDefaults.standard.string(forKey: "appTheme") ?? AppTheme.system.rawValue)?.colorScheme)
                    .environment(timer)
                    .environment(logger)
                    .environment(authManager)
                    .environment(taskService)
                    .environment(analyticsManager)
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
                    macOSContentView()
                    .environment(timer)
                    .environment(logger)
                    .environment(authManager)
                    .environment(taskService)
                    .environment(analyticsManager)
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
        timer.onFocusSessionCompleted = { record in
            logger.add(record: record)
        }
        if processInfo.arguments.contains("-focus-test-reset") {
            FocusTimerPersistence.clear()
            timer.reset()
        } else {
            timer.restorePersistedState()
        }
        if processInfo.arguments.contains("-ui-testing") ||
            processInfo.environment["SYNAPSE_UI_TESTING"] == "1" {
            try? WorkspaceUITestData.seedProjectsAndAreasIfRequested(
                in: ModelContext(SynapseModelContainer.shared)
            )
            try? WorkspaceUITestData.seedWeeklyReviewStaleItemIfRequested(
                in: ModelContext(SynapseModelContainer.shared)
            )
            try? WorkspaceUITestData.seedDailyBriefingIfRequested(
                in: ModelContext(SynapseModelContainer.shared)
            )
            try? WorkspaceUITestData.seedGmailIfRequested(
                in: ModelContext(SynapseModelContainer.shared)
            )
            isAppReady = true
            WeeklyReviewReminderService.shared.schedule()
            return
        }

        // Restore auth session
        await authManager.restoreSession()

        // Timer state is restored from local persistence above. There is no
        // remote timer backend to pull from.
        TimerSyncManager.shared.configure(with: timer)

        // Cache remote rollout changes for the next launch. The active flag
        // snapshot remains stable for the duration of this session.
        await featureFlags.refreshRemoteConfiguration()

        isAppReady = true
        UserDefaults.standard.set(true, forKey: SynapseModelContainer.appSetupCompletedKey)
        WeeklyReviewReminderService.shared.schedule()
    }
}
