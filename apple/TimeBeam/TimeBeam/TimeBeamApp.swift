import AppKit
import FirebaseCore
import SwiftUI
import UIKit
import UserNotifications

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

                        AnalyticsView()
                            .tabItem {
                                Label("Status", systemImage: "chart.bar.fill")
                            }
                            .tag(1)

                        SettingsView()
                            .tabItem {
                                Label("Profile", systemImage: "person.circle")
                            }
                            .tag(2)
                    }
                    .environmentObject(timer)
                    .environmentObject(logger)
                    .environmentObject(authManager)
                    .environmentObject(analyticsManager)
                    .accentColor(Color.themePrimary)
                    .tabViewStyle(.automatic)
                    .transition(.opacity)
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
            macOSContentView()
                .environmentObject(timer)
                .environmentObject(logger)
                .environmentObject(authManager)
                .environmentObject(analyticsManager)
                .onAppear {
                    Task {
                        print("🔄 macOS: Starting authentication and timer sync...")
                        await authManager.restoreSession()

                        // Wait a bit for authentication to complete, then sync timer
                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay

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
            Task {
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

        // Configure Firebase (without messaging for personal team compatibility)
        FirebaseApp.configure()

        return true
    }

    // MARK: - UNUserNotificationCenterDelegate
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
}
#endif
