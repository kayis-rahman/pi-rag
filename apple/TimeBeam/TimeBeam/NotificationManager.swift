import Foundation
import UserNotifications
#if os(watchOS)
import WatchKit
#endif

class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    func requestPermission(completion: ((Bool) -> Void)? = nil) {
        #if os(iOS) || os(macOS)
        print("Requesting notification permission...")
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            print("Notification permission granted: \(granted)")
            completion?(granted)
        }
        #else
        completion?(true)
        #endif
    }

    func sendSessionDoneNotification(phase: String) {
        #if os(iOS) || os(macOS)
        print("Sending session done notification for phase: \(phase)")
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
        UNUserNotificationCenter.current().add(request, withCompletionHandler: { error in
            if let error = error {
                print("Failed to add notification: \(error)")
            } else {
                print("Notification scheduled successfully.")
            }
        })
        #endif
        triggerHapticIfNeeded()
    }

    func triggerHapticIfNeeded() {
        #if os(watchOS)
        WKInterfaceDevice.current().play(.notification)
        #endif
    }
}
