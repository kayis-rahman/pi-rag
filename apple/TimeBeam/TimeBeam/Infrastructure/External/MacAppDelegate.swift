#if os(macOS)
import Cocoa
import SwiftUI
import UserNotifications
import _Concurrency

class MacAppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    static var shared: MacAppDelegate?
    private let notificationDelegate = NotificationDelegate()
    private static var statusItem: NSStatusItem?

    override init() {
        super.init()
        MacAppDelegate.shared = self
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = self

        // Request notification permissions for macOS
        requestNotificationPermissions()
        NSApplication.shared.registerForRemoteNotifications()

        if MacAppDelegate.statusItem == nil {
            let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            item.button?.title = ""
            item.button?.image = NSImage(systemSymbolName: "timer.circle.fill", accessibilityDescription: nil)
            MacAppDelegate.statusItem = item

            // Create menu
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.shared.terminate(_:)), keyEquivalent: ""))
            item.menu = menu
        }
    }

    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            print("Notification permission granted: \(granted)")
        }
    }

    // MARK: - Remote Notifications

    func application(_ application: NSApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("macOS APNs device token registered: \(token.prefix(8))...")
        Task {
            guard let accessToken = AuthManager.shared.getValidAccessToken() else { return }
            let deviceId = TimerSyncManager.shared.deviceId
            try? await ApiClient.shared.updateApnsToken(deviceId: deviceId, apnsToken: token, accessToken: accessToken)
        }
    }

    func application(_ application: NSApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("macOS APNs registration failed: \(error.localizedDescription)")
    }

    // MARK: - URL Handling (OAuth callback)

    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first else { return }
        Task {
            try? await AuthManager.shared.handleOAuthCallback(url)
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo

        // Handle timer sync notifications silently (no UI)
        if let type = userInfo["type"] as? String, type == "timer_sync" {
            print("Received timer sync notification on macOS (willPresent)")

            // Apply timer state directly from push payload
            Task { [weak self] in
                await MainActor.run {
                    self?.applyStateFromPush(userInfo)
                }
            }

            // Don't show notification for silent sync messages
            completionHandler([])
            return
        }

        // Show regular notifications
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo

        if let type = userInfo["type"] as? String, type == "timer_sync" {
            print("Received timer sync notification on macOS (didReceive)")

            // Apply timer state directly from push payload when user taps
            Task { [weak self] in
                await MainActor.run {
                    self?.applyStateFromPush(userInfo)
                }
            }
        }

        completionHandler()
    }

    private func applyStateFromPush(_ userInfo: [AnyHashable: Any]) {
        TimerSyncManager.shared.applyEventState(from: userInfo)
    }
}
#endif
