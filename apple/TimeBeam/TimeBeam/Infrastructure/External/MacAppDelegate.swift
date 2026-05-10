#if os(macOS)
import Cocoa
import SwiftUI
import UserNotifications
import _Concurrency

class MacAppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    static var shared: MacAppDelegate?
    private let notificationDelegate = NotificationDelegate()
    private static var statusItem: NSStatusItem?
    private var pendingApnsToken: String?

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
        pendingApnsToken = token
        Task {
            await registerApnsTokenWhenReady(token: token)
        }
    }

    @MainActor
    private func registerApnsTokenWhenReady(token: String, retries: Int = 6) async {
        for attempt in 0..<retries {
            if let accessToken = AuthManager.shared.getValidAccessToken() {
                let deviceId = TimerSyncManager.shared.deviceId
                try? await ApiClient.shared.updateApnsToken(deviceId: deviceId, apnsToken: token, accessToken: accessToken)
                pendingApnsToken = nil
                return
            }
            if attempt < retries - 1 {
                try? await _Concurrency.Task.sleep(nanoseconds: 2_000_000_000)
            }
        }
    }

    func application(_ application: NSApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("macOS APNs registration failed: \(error.localizedDescription)")
    }

    // Silent (background) push: aps:{content-available:1} bypasses the
    // notification center delegate and lands here even when the app is foreground.
    func application(_ application: NSApplication, didReceiveRemoteNotification userInfo: [String: Any]) {
        if let type = userInfo["type"] as? String, type == "timer_sync" {
            print("Received silent timer_sync push on macOS")
            _Concurrency.Task { [weak self] in
                await MainActor.run {
                    self?.applyStateFromPush(userInfo as [AnyHashable: Any])
                }
            }
        }
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

    @MainActor
    private func applyStateFromPush(_ userInfo: [AnyHashable: Any]) {
        TimerSyncManager.shared.applyEventState(from: userInfo)
    }
}
#endif
