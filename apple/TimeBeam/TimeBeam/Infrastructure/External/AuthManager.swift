import AuthenticationServices
import Combine

import Foundation
import _Concurrency

#if os(iOS)
import GoogleSignIn
import UIKit
#endif

#if os(macOS)
import AppKit
#endif

//
//  AuthManager.swift
//  TimeBeam
//
//  Created by Kayis Rahman on 03/11/25.
//

@MainActor
final class AuthManager: ObservableObject {
    @Published var isSignedIn: Bool = false
    @Published var displayName: String? = nil
    @Published var email: String? = nil

    // MARK: - Public API

    func restoreSession() async {
        #if DEBUG
        print("[Auth] restoreSession: begin")
        #endif

        // Prefer backend access token as sign-in indicator
        let backendToken = try? KeychainStore.loadString(.accessToken)
        let cachedName = try? KeychainStore.loadString(.userDisplayName)
        let cachedEmail = try? KeychainStore.loadString(.userEmail)

        #if os(iOS)
        if GIDSignIn.sharedInstance.hasPreviousSignIn() {
            do {
                #if DEBUG
                print("[Auth] restoreSession: attempting Google restorePreviousSignIn with timeout")
                #endif

                // Restore previous sign-in
                let user = try await GIDSignIn.sharedInstance.restorePreviousSignIn()

                await applyUser(user)
                #if DEBUG
                print("[Auth] restoreSession: Google restore success, applied user")
                #endif
                return
            } catch {
                #if DEBUG
                print("[Auth] restoreSession: Google restore failed: \(error)")
                #endif
                // Fall through to Keychain fallback
            }
        }
        #endif

        // Fallback to cached data from Keychain
        await MainActor.run {
            self.isSignedIn = (backendToken?.isEmpty == false)
            if let name = cachedName, !name.isEmpty { self.displayName = name }
            if let mail = cachedEmail, !mail.isEmpty { self.email = mail }
        }

        #if DEBUG
        print("[Auth] restoreSession: completed with isSignedIn=\(self.isSignedIn)")
        #endif
    }

    func signOut() async {
        #if DEBUG
        print("[Auth] signOut: begin")
        #endif

        #if os(iOS)
        GIDSignIn.sharedInstance.signOut()
        #endif

        try? KeychainStore.clear(.idToken)
        try? KeychainStore.clear(.accessToken)
        try? KeychainStore.clear(.userDisplayName)
        try? KeychainStore.clear(.userEmail)
        self.isSignedIn = false
        self.displayName = nil
        self.email = nil

        WatchConnectivityManager.shared?.pushAuthStateToCounterpart(
            isSignedIn: false,
            displayName: nil,
            email: nil
        )

        #if DEBUG
        print("[Auth] signOut: completed")
        #endif
    }

    // MARK: - Sign In

    #if os(iOS)
    func signInWithGoogle(presentingAnchor: ASPresentationAnchor?) async throws {
        #if DEBUG
        print("[Auth] signInWithGoogle(iOS, anchor): begin")
        #endif

        guard let presenter = try await presentingViewController(from: presentingAnchor) else {
            #if DEBUG
            print("[Auth] signInWithGoogle(iOS, anchor): no presenter")
            #endif
            throw SignInError.noPresenter
        }
        let config = GIDConfiguration(clientID: clientID())
        GIDSignIn.sharedInstance.configuration = config

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenter)
        #if DEBUG
        print("[Auth] signInWithGoogle(iOS, anchor): Google sign-in success, applying user")
        #endif
        try await applySignInResult(result)
    }

    func signInWithGoogle() async throws {
        #if DEBUG
        print("[Auth] signInWithGoogle(iOS): begin")
        #endif

        let presenter = await topViewController()
        guard let presenter else {
            #if DEBUG
            print("[Auth] signInWithGoogle(iOS): no presenter")
            #endif
            throw SignInError.noPresenter
        }

        let config = GIDConfiguration(clientID: clientID())
        GIDSignIn.sharedInstance.configuration = config

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenter)
        #if DEBUG
        print("[Auth] signInWithGoogle(iOS): Google sign-in success, applying user")
        #endif
        try await applySignInResult(result)
    }
    #elseif os(macOS)
    func signInWithGoogle() async throws {
        #if DEBUG
        print("[Auth] signInWithGoogle(macOS): Starting real OAuth flow")
        #endif

        // Create Google OAuth URL with proper encoding
        let clientId = clientID()
        let redirectUri = "com.sparkage.time-beam:/oauth2redirect"
        let scope = "openid email profile"

        var components = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectUri),
            URLQueryItem(name: "scope", value: scope),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "access_type", value: "offline")
        ]

        guard let url = components?.url else {
            throw SignInError.invalidRequest
        }

        #if DEBUG
        print("[Auth] signInWithGoogle(macOS): OAuth URL: \(url.absoluteString)")
        #endif

        // Open in default browser
        await MainActor.run {
            NSWorkspace.shared.open(url)
        }

        #if DEBUG
        print("[Auth] signInWithGoogle(macOS): Browser opened - waiting for OAuth callback")
        #endif
    }

    // Handle OAuth callback and complete sign-in
    func handleOAuthCallback(_ url: URL) async throws {
        #if DEBUG
        print("[Auth] handleOAuthCallback: OAuth callback received: \(url.absoluteString)")
        #endif

        // TODO: Implement OAuth token exchange
        print("OAuth callback received - token exchange implementation pending")
    }
    #endif

    enum SignInError: Error {
        case noPresenter
        case sdkUnavailable
        case invalidRequest
        case invalidResponse
    }

    // MARK: - iOS presenters

    #if os(iOS)
    private func presentingViewController(from anchor: ASPresentationAnchor?) async -> UIViewController? {
        await MainActor.run {
            if let window = anchor as? UIWindow {
                return window.rootViewController ?? topViewController()
            }
            return topViewController()
        }
    }

    private func topViewController(base: UIViewController? = UIApplication.shared.connectedScenes
        .compactMap { ($0 as? UIWindowScene)?.keyWindow }
        .first?.rootViewController) -> UIViewController? {

        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            return topViewController(base: tab.selectedViewController)
        }
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        return base
    }
    #endif

    // MARK: - macOS presenter

    #if os(macOS)
    private func macOSPresentationWindow() -> NSWindow? {
        if let key = NSApplication.shared.keyWindow {
            return key
        }
        if let main = NSApplication.shared.mainWindow {
            return main
        }
        return NSApplication.shared.windows.first
    }
    #endif

    // MARK: - Device Registration

    private func registerCurrentDevice(accessToken: String) async throws {
        let deviceId = TimerSyncManager.shared.deviceId

        #if os(iOS)
        let deviceType = "ios"
        let deviceName = await UIDevice.current.name
        let platformVersion = await UIDevice.current.systemVersion
        #elseif os(macOS)
        let deviceType = "macos"
        let deviceName = Host.current().localizedName ?? "Mac"
        let platformVersion = ProcessInfo.processInfo.operatingSystemVersionString
        #else
        let deviceType = "unknown"
        let deviceName = "Unknown Device"
        let platformVersion = nil
        #endif

        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String

        let registration = ApiClient.DeviceRegistrationDto(
            deviceId: deviceId,
            deviceName: deviceName,
            deviceType: deviceType,
            platformVersion: platformVersion,
            appVersion: appVersion,
            fcmToken: nil  // APNs token will be registered separately
        )

        try await ApiClient.shared.registerDevice(registration, accessToken: accessToken)
    }

    // MARK: - Config

    private func clientID() -> String {
        if let dict = Bundle.main.infoDictionary,
            let cid = dict["GOOGLE_CLIENT_ID"] as? String,
            !cid.isEmpty {
            return cid
        }
        return "512741716533-iks9gube8oh8f0gopnmc3v72pe6u3p5m.apps.googleusercontent.com"
    }

    // MARK: - Redaction helpers

    private func redactEmail(_ email: String) -> String {
        guard let at = email.firstIndex(of: "@") else { return email.isEmpty ? "<empty>" : "<redacted>" }
        let name = email[..<at]
        let domain = email[email.index(after: at)...]
        let shown = name.prefix(2)
        return "\(shown)***@\(domain)"
    }
}
