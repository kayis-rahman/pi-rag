import SwiftUI
import UserNotifications
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
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

    #if os(macOS)
    @StateObject var authManager = AuthManager()
    #endif

    var body: some Scene {
        WindowGroup {
            #if os(iOS)
            TabView {
                ContentView()
                    .tabItem {
                        Label("Timer", systemImage: "timer")
                    }

                StatsView()
                    .tabItem {
                        Label("Stats", systemImage: "chart.bar")
                    }

                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
            }
            .environmentObject(timer)
            .environmentObject(logger)
            .accentColor(Color.themePrimary)
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
            }
            #else
            ContentView()
                .environmentObject(timer)
                .environmentObject(logger)
                .environmentObject(authManager)
                .onAppear {
                    Task { await authManager.restoreSession() }
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
                }
            #endif
        }
        #if os(macOS)
        .windowStyle(.automatic)
        #endif
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
final class iOSAppDelegate: NSObject, UIApplicationDelegate {
    private let notificationDelegate = NotificationDelegate()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = notificationDelegate
        return true
    }
}
#endif
