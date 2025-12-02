import Foundation

class NotificationManager {
    static let shared = NotificationManager()

    private init() {}

    func requestPermission(completion: ((Bool) -> Void)? = nil) {
        completion?(true)
    }

    func sendSessionDoneNotification(phase: String) {
        // No-op for watchOS - haptic feedback handled by system
    }
}
