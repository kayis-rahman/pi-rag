import Foundation

final class WatchConnectivityDelegate: NSObject, WCSessionDelegate {
    @Published var isReachable = false

    func sessionDidBecomeInactive(_ session: WCSession) {
        isReachable = false
    }

    func sessionDidActivate(_ session: WCSession) {
        isReachable = true
    }

    func session(_ session: WCSession, didReceiveMessageData: Data) {
        // Handle incoming messages from watch
        AppLogger.info("Received message from watch", category: .sync)
    }

    func session(_ session: WCSession, didReceiveUserInfo: WCSessionUserInfo) {
        // Handle user info transfer
        AppLogger.info("Received user info from watch", category: .sync)
    }
}
