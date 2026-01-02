import Combine
import Foundation

#if os(iOS) || os(watchOS)
import WatchConnectivity
#endif

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
    func broadcastTimerState() {
        guard let timer = TimerSyncManager.shared.getTimer() else { return }
        let state = [
            "startTimestamp": timer.startTimestamp as Any,
            "pauseTimestamp": timer.pauseTimestamp as Any,
            "totalDuration": timer.currentDuration,
            "remainingSeconds": Int(timer.remainingSeconds),
            "phase": timer.phase.rawValue,
            "isRunning": timer.isRunning,
            "workDuration": timer.workDuration,
            "breakDuration": timer.breakDuration,
            "longBreakDuration": timer.longBreakDuration,
            "autoStartNextSession": timer.autoStartNextSession,
            "shortBreaksCompleted": timer.shortBreaksCompleted,
            "lastModifiedTimestamp": timer.lastModifiedTimestamp
        ] as [String: Any]

        let payload: [String: Any] = [
            Keys.timerSync: true,
            Keys.timerState: state
        ]

        sendMessage(payload)
    }

    func handleIncomingTimerSync(_ message: [String: Any]) {
        guard message[Keys.timerSync] as? Bool == true else { return }

        if let stateDict = message[Keys.timerState] as? [String: Any] {
            // Apply the state directly
            TimerSyncManager.shared.applyIncomingState(stateDict)
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
