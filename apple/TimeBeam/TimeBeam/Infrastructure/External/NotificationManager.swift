import Foundation
import UserNotifications
import WatchKit

#if os(watchOS)
#endif

open class NotificationManager {
    // Allow tests to replace the shared instance
    public static var shared: NotificationManager = NotificationManager()
    public init() {}

    // Helper for tests to restore default shared instance
    public static func resetShared() { shared = NotificationManager() }

    open func requestPermission(completion: ((Bool) -> Void)? = nil) {
        #if os(iOS) || os(macOS)
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            completion?(granted)
        }
        #else
        completion?(true)
        #endif
    }

    open func sendSessionDoneNotification(phase: String) {
        #if os(iOS) || os(macOS)
        let content = UNMutableNotificationContent()
        content.title = "Time Beam"
        if phase == "work" {
            content.body = "Work session done! Time for a break."
        } else {
            content.body = "Break session done! Time to focus."
        }
        if let _ = Bundle.main.url(forResource: "chime-sound", withExtension: "mp3") {
            content.sound = UNNotificationSound(named: UNNotificationSoundName("chime-sound.mp3"))
        } else {
            content.sound = .default
        }
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        #endif
        triggerHapticIfNeeded()
    }

    func triggerHapticIfNeeded() {
        #if os(watchOS)
        WKInterfaceDevice.current().play(.notification)
        #endif
    }
}
