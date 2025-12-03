import Combine
import Foundation
import WatchConnectivity

//
//  WatchConnectivityManager.swift
//  TimeBeam
//
//  Created by Kayis Rahman on 03/11/25.
//

#if os(iOS)
#endif

@MainActor
final class WatchConnectivityManager: ObservableObject {
    static var shared: WatchConnectivityManager? = WatchConnectivityManager()

    private enum Keys {
        static let requestSignIn = "requestSignIn"
        static let authState = "authState"
        static let isSignedIn = "isSignedIn"
        static let displayName = "displayName"
        static let email = "email"

        // Timer sync keys
        static let timerState = "timerState"
        static let timerEvent = "timerEvent"
        static let timerSync = "timerSync"
    }

    #if os(iOS)
    private var session: WCSession?
    #endif

    init() {
        #if os(iOS)
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = WatchConnectivityDelegate.shared
            session?.activate()
        }
        #endif
    }

    // MARK: - Timer Sync Methods
    func broadcastTimerAction(_ message: TimerSyncManager.ActionMessage) {
        let payload: [String: Any] = [
            Keys.timerSync: true,
            Keys.timerState: try! JSONEncoder().encode(message)
        ]

        sendMessage(payload)
    }

    func handleIncomingTimerSync(_ message: [String: Any]) {
        guard message[Keys.timerSync] as? Bool == true else { return }

        if let actionData = message[Keys.timerState] as? Data,
           let actionMessage = try? JSONDecoder().decode(TimerSyncManager.ActionMessage.self, from: actionData) {

            TimerSyncManager.shared.handleIncomingAction(
                actionMessage.action,
                from: actionMessage.deviceId,
                timestamp: actionMessage.timestamp
            )
        }
    }

    func requestSignInOnPhone() {
        sendMessage([Keys.requestSignIn: true])
    }

    func pushAuthStateToCounterpart(isSignedIn: Bool, displayName: String?, email: String?) {
        let payload: [String: Any] = [
            Keys.authState: true,
            Keys.isSignedIn: isSignedIn,
            Keys.displayName: displayName ?? NSNull(),
            Keys.email: email ?? NSNull()
        ]
        sendMessage(payload)
    }

    func handleIncomingMessage(_ message: [String: Any], authManager: AuthManager) {
        if message[Keys.requestSignIn] as? Bool == true {
            #if os(iOS)
            presentSignInFlowFromConnectivity()
            #endif
        } else if message[Keys.authState] as? Bool == true {
            let signedIn = message[Keys.isSignedIn] as? Bool ?? false
            let name = message[Keys.displayName] as? String
            let mail = message[Keys.email] as? String

            authManager.isSignedIn = signedIn
            authManager.displayName = name
            authManager.email = mail

            try? KeychainStore.saveString(name ?? "", for: .userDisplayName)
            try? KeychainStore.saveString(mail ?? "", for: .userEmail)
            if !signedIn {
                try? KeychainStore.clear(.idToken)
                try? KeychainStore.clear(.accessToken)
            }
        }
    }

    private func sendMessage(_ message: [String: Any]) {
        #if os(iOS)
        guard let session = session, session.isReachable else {
            print("Watch not reachable, message not sent")
            return
        }

        session.sendMessage(message, replyHandler: nil) { error in
            print("Failed to send message: \(error.localizedDescription)")
        }
        #elseif os(watchOS)
        guard WCSession.default.isReachable else {
            // watchOS doesn't have LoggerStore, use print for now
            print("iOS not reachable, message not sent")
            return
        }

        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            print("Failed to send message: \(error.localizedDescription)")
        }
        #endif
    }

    #if os(iOS)
    private func presentSignInFlowFromConnectivity() {
        // TODO: Locate a presentation anchor and call:
        // Task { try await authManager.signInWithGoogle(presentingAnchor: window) }
    }
    #endif
}

#if os(iOS)
// MARK: - WatchConnectivity Delegate
final class WatchConnectivityDelegate: NSObject, WCSessionDelegate {
    static let shared = WatchConnectivityDelegate()

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed: \(error.localizedDescription)")
        } else {
            print("WCSession activated with state: \(activationState.rawValue)")
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        print("WCSession became inactive")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        print("WCSession deactivated")
        // Reactivate session
        session.activate()
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        print("Received message from counterpart")

        Task { @MainActor in
            // Handle timer sync messages
            WatchConnectivityManager.shared?.handleIncomingTimerSync(message)

            // Handle auth messages (existing functionality)
            // This would need access to AuthManager - for now, timer sync is prioritized
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        print("Watch reachability changed: \(session.isReachable)")
    }
}
#endif
