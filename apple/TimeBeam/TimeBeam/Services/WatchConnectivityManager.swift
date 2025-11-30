//
//  WatchConnectivityManager.swift
//  TimeBeam
//
//  Created by Kayis Rahman on 03/11/25.
//


import Foundation
import Combine

@MainActor
final class WatchConnectivityManager: ObservableObject {
    static var shared: WatchConnectivityManager? = WatchConnectivityManager()

    private enum Keys {
        static let requestSignIn = "requestSignIn"
        static let authState = "authState"
        static let isSignedIn = "isSignedIn"
        static let displayName = "displayName"
        static let email = "email"
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
        // Implement with WatchConnectivity (WCSession)
    }

    #if os(iOS)
    private func presentSignInFlowFromConnectivity() {
        // TODO: Locate a presentation anchor and call:
        // Task { try await authManager.signInWithGoogle(presentingAnchor: window) }
    }
    #endif
}
