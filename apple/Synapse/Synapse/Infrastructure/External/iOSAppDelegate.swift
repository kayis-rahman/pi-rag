import SwiftUI
import UserNotifications

#if os(iOS)
import UIKit

final class iOSAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        requestNotificationPermissions()
        return true
    }

    private func requestNotificationPermissions() {
        AppLogger.info("Requesting notification permissions on iOS", category: .general)
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            AppLogger.info("iOS notification permission granted: \(granted)", category: .general)
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        if let type = userInfo["type"] as? String,
           type == "weekly_review",
           let deepLink = userInfo["deepLink"] as? String,
           let url = URL(string: deepLink) {
            UIApplication.shared.open(url)
        }
        completionHandler()
    }

    @MainActor
    func applicationDidEnterBackground(_ application: UIApplication) {
        TimerSyncManager.shared.getTimer()?.persistState()
    }

    @MainActor
    func applicationWillEnterForeground(_ application: UIApplication) {
        TimerSyncManager.shared.getTimer()?.reconcile()
    }
}
#endif
