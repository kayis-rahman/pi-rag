import SwiftUI
import UserNotifications

#if os(macOS)
import AppKit
#endif

#if os(iOS)
import UIKit
#endif

#if os(macOS)
#elseif os(iOS)
#endif

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        #if os(macOS)
        if #available(macOS 11.0, *) {
            completionHandler([.banner, .sound])
        } else {
            completionHandler([.sound])
        }
        #else
        completionHandler([.banner, .sound, .badge])
        #endif
    }
}

@main
struct TimeBeamApp: App {
    #if os(macOS)
    @NSApplicationDelegateAdaptor(MacAppDelegate.self) var appDelegate
    #else
    @UIApplicationDelegateAdaptor(iOSAppDelegate.self) var appDelegate
    #endif

    @StateObject var timer = PomodoroTimer()
    @StateObject var logger = SessionLogger()
    @StateObject var authManager = AuthManager()
    @StateObject var taskService = TaskService()
    @StateObject var analyticsManager = AnalyticsManager(
        apiClient: AnalyticsApiClient(baseURL: ApiClient.Configuration.fromInfoPlist()?.baseURL ?? URL(string: "http://localhost:8080")!),
        authManager: AuthManager()
    )

    @State private var isAppReady = false

    var body: some Scene {
        WindowGroup {
            #if os(iOS)
            Group {
                if isAppReady {
                    TabView {
                        iOSContentView()
                            .tabItem {
                                Label("Home", systemImage: "house.fill")
                            }
                            .tag(0)

                        TaskListView()
                            .tabItem {
                                Label("Tasks", systemImage: "checklist")
                            }
                            .tag(1)

                        AnalyticsView()
                            .tabItem {
                                Label("Status", systemImage: "chart.bar.fill")
                            }
                            .tag(2)

                        SettingsView()
                            .tabItem {
                                Label("Profile", systemImage: "person.circle")
                            }
                            .tag(3)
                    }
                    .environmentObject(timer)
                    .environmentObject(logger)
                    .environmentObject(authManager)
                    .environmentObject(taskService)
                    .environmentObject(analyticsManager)
                    .accentColor(Color.themePrimary)
                    .tabViewStyle(.automatic)
                    .transition(.opacity)
                } else {
                    LoadingView()
                        .onAppear {
                            _Concurrency.Task {
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
                .onAppear {
                    // Initialize file logging system
                    AppLogger.initializeFileLogging()
                    
                    _Concurrency.Task {
                        print("🔄 macOS: Starting authentication and timer sync...")
                        await authManager.restoreSession()

                        // Wait a bit for authentication to complete, then sync timer
                        try? await _Concurrency.Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay

                        if let _ = try? KeychainStore.loadString(.accessToken) {
                            AppLogger.info("Authentication complete, starting smart timer sync", category: .sync)
                            await TimerSyncManager.shared.smartSyncWithBackend()
                        } else {
                            AppLogger.warning("No access token after authentication, skipping timer sync", category: .sync)
                        }
                    }
                }
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

                    // Configure timer sync manager
                    TimerSyncManager.shared.configure(with: timer)
                }
            #endif
        }
        #if os(macOS)
        .windowStyle(.automatic)
        #endif
    }

    private func setupApp() async {
        // Initialize file logging system
        AppLogger.initializeFileLogging()

        // Initialize iCloud sync
        _ = iCloudSyncManager.shared

        // Load timer settings from iCloud
        if let iCloudSettings = iCloudSyncManager.shared.loadTimerSettings() {
            timer.updateDurations(
                workMinutes: iCloudSettings.workDuration / 60,
                shortBreakMinutes: iCloudSettings.breakDuration / 60,
                longBreakMinutes: iCloudSettings.longBreakDuration / 60
            )
            timer.autoStartNextSession = iCloudSettings.autoStartNextSession
            AppLogger.info("Loaded timer settings from iCloud", category: .sync)
        }

        // Restore authentication state
        await authManager.restoreSession()

        // Setup timer completion handler
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

        // Configure timer sync manager
        TimerSyncManager.shared.configure(with: timer)

        // Smart sync timer state with conflict resolution
        if let accessToken = try? KeychainStore.loadString(.accessToken) {
            AppLogger.info("Found access token after login, starting smart timer sync", category: .sync)
            _Concurrency.Task {
                await TimerSyncManager.shared.smartSyncWithBackend()
                AppLogger.info("Smart timer sync completed", category: .sync)
            }
        } else {
            AppLogger.warning("No access token found after login, skipping timer sync", category: .sync)
        }

        // Mark app as ready
        isAppReady = true
    }
}

// MARK: - Loading View

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.themeBackground.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // App logo/icon
                Image(systemName: "timer.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(Color.themePrimary)

                // Loading text
                Text("TimeBeam")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Color.themeTextPrimary)

                Text("Setting up your workspace...")
                    .font(.system(size: 16))
                    .foregroundColor(Color.themeTextSecondary)

                // Loading indicator
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color.themePrimary))
                    .scaleEffect(1.2)

                Spacer()
            }
            .padding(.horizontal, 24)
        }
    }
}

#if os(macOS)
final class MacAppDelegate: NSObject, NSApplicationDelegate {
    static var shared: MacAppDelegate?
    private let notificationDelegate = NotificationDelegate()
    private static var statusItem: NSStatusItem?

    override init() {
        super.init()
        MacAppDelegate.shared = self
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = notificationDelegate
        if MacAppDelegate.statusItem == nil {
            let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            item.button?.title = ""
            MacAppDelegate.statusItem = item
        }
    }

    static func updateStatusItem(title: String?) {
        DispatchQueue.main.async {
            if let title, !title.isEmpty {
                MacAppDelegate.statusItem?.button?.title = title
            } else {
                MacAppDelegate.statusItem?.button?.title = ""
            }
        }
    }
}
#endif

#if os(iOS)
final class iOSAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    private let notificationDelegate = NotificationDelegate()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self

        // Request notification permissions
        requestNotificationPermissions()

        return true
    }

    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
            if let error = error {
                AppLogger.error("Failed to request notification permissions: \(error.localizedDescription)", category: .general)
            }
        }
    }

    // MARK: - APNs Token Registration
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        AppLogger.info("Successfully registered for remote notifications, APNs token: \(tokenString)", category: .general)

        // Store APNs token with backend
        _Concurrency.Task {
            await updateApnsTokenWithBackend(tokenString)
        }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        AppLogger.error("Failed to register for remote notifications: \(error.localizedDescription)", category: .general)
    }

    private func updateApnsTokenWithBackend(_ apnsToken: String) async {
        guard let accessToken = try? KeychainStore.loadString(.accessToken),
              let config = ApiClient.Configuration.fromInfoPlist() else {
            AppLogger.warning("No access token or API config available for APNs token update", category: .general)
            return
        }

        let deviceId = TimerSyncManager.shared.deviceId
        let apiClient = ApiClient(configuration: config)

        do {
            try await apiClient.updateApnsToken(deviceId: deviceId, apnsToken: apnsToken, accessToken: accessToken)
            AppLogger.info("APNs token updated with backend for device: \(deviceId)", category: .general)
        } catch {
            AppLogger.error("Failed to update APNs token with backend: \(error.localizedDescription)", category: .general)
        }
    }

    // MARK: - UNUserNotificationCenterDelegate
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Handle data-only (silent) notifications
        let userInfo = notification.request.content.userInfo

        if let type = userInfo["type"] as? String, type == "timer_sync" {
            AppLogger.info("Received timer sync FCM message", category: .sync)

            // Trigger timer sync in background
            _Concurrency.Task {
                await TimerSyncManager.shared.smartSyncWithBackend()
            }

            // Don't show notification for silent sync messages
            completionHandler([])
            return
        }

        // Show regular notifications
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo

        if let type = userInfo["type"] as? String, type == "timer_sync" {
            AppLogger.info("User tapped timer sync notification", category: .sync)

            // Trigger timer sync when user taps notification
            _Concurrency.Task {
                await TimerSyncManager.shared.smartSyncWithBackend()
            }
        }

        completionHandler()
    }
}
#endif
