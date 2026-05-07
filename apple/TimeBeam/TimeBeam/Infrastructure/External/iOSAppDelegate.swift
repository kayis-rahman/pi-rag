import SwiftUI
import UserNotifications

#if os(iOS)
import UIKit

class iOSAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    private let notificationDelegate = NotificationDelegate()

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

    private func applyStateFromPush(_ userInfo: [AnyHashable: Any]) {
        TimerSyncManager.shared.applyEventState(from: userInfo)
    }
}
#endif
