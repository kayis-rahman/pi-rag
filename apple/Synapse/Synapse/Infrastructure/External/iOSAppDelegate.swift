import SwiftUI
import UserNotifications

#if os(iOS)
import UIKit

class iOSAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    private let notificationDelegate = NotificationDelegate()
    private var pendingApnsToken: String?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self

        // Request notification permissions
        requestNotificationPermissions()

        return true
    }

    private func requestNotificationPermissions() {
        AppLogger.info("Requesting notification permissions on iOS", category: .general)
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            AppLogger.info("iOS notification permission granted: \(granted)", category: .general)
            if granted {
                DispatchQueue.main.async {
                    AppLogger.info("Registering for remote notifications on iOS", category: .general)
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }

    // MARK: - UNUserNotificationCenterDelegate
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo

        // Handle timer sync notifications silently (no UI)
        if let type = userInfo["type"] as? String, type == "timer_sync" {
            AppLogger.info("Received timer sync notification on iOS (willPresent)", category: .sync)

            // Apply timer state directly from push payload
            _Concurrency.Task { [weak self] in
                await MainActor.run {
                    self?.applyStateFromPush(userInfo)
                }
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

        if let type = userInfo["type"] as? String, type == "weekly_review",
           let deepLink = userInfo["deepLink"] as? String, let url = URL(string: deepLink) {
            DispatchQueue.main.async { UIApplication.shared.open(url) }
        }

        if let type = userInfo["type"] as? String, type == "timer_sync" {
            AppLogger.info("User tapped timer sync notification on iOS", category: .sync)

            // Apply timer state directly from push payload when user taps
            _Concurrency.Task { [weak self] in
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

    // MARK: - Remote Notifications

    func application(_ app: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        AppLogger.info("iOS APNs token registered: \(token.prefix(8))...", category: .general)
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

    func application(_ app: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        AppLogger.error("iOS APNs registration failed: \(error.localizedDescription)", category: .general)
    }

    @MainActor
    func applicationDidEnterBackground(_ application: UIApplication) {
        TimerSyncManager.shared.getTimer()?.persistState()
    }

    @MainActor
    func applicationWillEnterForeground(_ application: UIApplication) {
        TimerSyncManager.shared.getTimer()?.reconcile()
    }

    // Silent (background) push: aps:{content-available:1} bypasses the
    // notification center delegate and lands here regardless of foreground state.
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        if let type = userInfo["type"] as? String, type == "timer_sync" {
            AppLogger.info("Received silent timer_sync push on iOS", category: .sync)
            _Concurrency.Task { [weak self] in
                await MainActor.run {
                    self?.applyStateFromPush(userInfo)
                }
                completionHandler(.newData)
            }
            return
        }
        completionHandler(.noData)
    }
}
#endif
