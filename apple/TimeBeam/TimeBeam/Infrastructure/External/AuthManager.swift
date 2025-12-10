import AuthenticationServices
import Combine

import Foundation
import _Concurrency
import GoogleSignIn

#if os(macOS)
import AppKit
#endif

#if os(iOS)
import UIKit
#endif

//
//  AuthManager.swift
//  TimeBeam
//
//  Created by Kayis Rahman on 03/11/25.
//

#if os(iOS)
#endif

#if os(macOS)
#endif

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

        #if os(iOS) || os(macOS)
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

        #if os(iOS) || os(macOS)
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
        print("[Auth] signInWithGoogle(macOS): begin")
        print("[Auth] signInWithGoogle(macOS): clientID = \(clientID())")
        #endif

        let config = GIDConfiguration(clientID: clientID())
        GIDSignIn.sharedInstance.configuration = config

        #if DEBUG
        print("[Auth] signInWithGoogle(macOS): configuration set, clientID = \(config.clientID)")
        #endif

        guard let window = macOSPresentationWindow() else {
            #if DEBUG
            print("[Auth] signInWithGoogle(macOS): no presenter - macOSPresentationWindow() returned nil")
            print("[Auth] signInWithGoogle(macOS): keyWindow = \(NSApplication.shared.keyWindow?.description ?? "nil")")
            print("[Auth] signInWithGoogle(macOS): mainWindow = \(NSApplication.shared.mainWindow?.description ?? "nil")")
            print("[Auth] signInWithGoogle(macOS): windows count = \(NSApplication.shared.windows.count)")
            #endif
            throw SignInError.noPresenter
        }

        #if DEBUG
        print("[Auth] signInWithGoogle(macOS): window found = \(window.description)")
        print("[Auth] signInWithGoogle(macOS): calling GIDSignIn.sharedInstance.signIn()")
        #endif

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: window)
            #if DEBUG
            print("[Auth] signInWithGoogle(macOS): Google sign-in success, applying user")
            #endif
            try await applySignInResult(result)
        } catch {
            #if DEBUG
            print("[Auth] signInWithGoogle(macOS): signIn() threw error = \(error)")
            print("[Auth] signInWithGoogle(macOS): error domain = \((error as NSError).domain)")
            print("[Auth] signInWithGoogle(macOS): error code = \((error as NSError).code)")
            print("[Auth] signInWithGoogle(macOS): error description = \((error as NSError).localizedDescription)")
            #endif
            throw error
        }
    }
    #else
    // watchOS and other platforms: no-op sign-in (sign-in is delegated to iPhone/macOS)
    func signInWithGoogle() async throws {
        #if DEBUG
        print("[Auth] signInWithGoogle(watchOS/other): SDK unavailable")
        #endif
        throw SignInError.sdkUnavailable
    }
    #endif

    // MARK: - Private helpers

    private func completeSignIn(idToken: String, accessToken: String, name: String, mail: String) throws {
        #if DEBUG
        print("[Auth] completeSignIn: saving tokens and user info (idTokenLen=\(idToken.count), accessTokenLen=\(accessToken.count), nameLen=\(name.count), emailRedacted=\(redactEmail(mail)))")
        #endif

        try KeychainStore.saveString(idToken, for: .idToken)
        try KeychainStore.saveString(accessToken, for: .accessToken)
        try KeychainStore.saveString(name, for: .userDisplayName)
        try KeychainStore.saveString(mail, for: .userEmail)

        self.isSignedIn = true
        self.displayName = name
        self.email = mail

        WatchConnectivityManager.shared?.pushAuthStateToCounterpart(
            isSignedIn: true,
            displayName: name,
            email: mail
        )

        #if DEBUG
        print("[Auth] completeSignIn: finished, isSignedIn=true")
        #endif
    }

    #if os(iOS) || os(macOS)
    private func applyUser(_ user: GIDGoogleUser) async {
        #if DEBUG
        print("[Auth] applyUser: begin")
        #endif

        let idToken = user.idToken?.tokenString ?? ""
        let name = user.profile?.name ?? ""
        let mail = user.profile?.email ?? ""

        #if DEBUG
        print("[Auth] applyUser: got Google user (nameLen=\(name.count), emailRedacted=\(redactEmail(mail)), idTokenLen=\(idToken.count))")
        #endif

        // Backend API call after Google sign-in succeeded (login only; register skipped)
        do {
            #if DEBUG
            print("[Auth] applyUser: preparing ApiClient config from Info.plist")
            #endif
            guard let cfg = ApiClient.Configuration.fromInfoPlist() else {
                #if DEBUG
                print("[Auth] applyUser: missing API configuration")
                #endif
                throw ApiClient.ApiError.missingConfiguration
            }
            let api = ApiClient(configuration: cfg)

            #if DEBUG
            print("[Auth] applyUser: calling backend login for emailRedacted=\(redactEmail(mail))")
            #endif
            let login = try await api.login(email: mail)

            #if DEBUG
            print("[Auth] applyUser: backend login success (accessTokenLen=\(login.accessToken.count))")
            #endif

            // Persist tokens and user info
            try completeSignIn(idToken: idToken, accessToken: login.accessToken, name: name, mail: mail)

            // Register device for push notifications
            do {
                try await registerCurrentDevice(accessToken: login.accessToken)
                AppLogger.info("Device registered successfully after login", category: .auth)

                // Also register APNs token if available
                if let apnsToken = try? KeychainStore.loadString(.apnsToken) {
                    do {
                        try await ApiClient.shared.updateApnsToken(deviceId: TimerSyncManager.shared.deviceId, apnsToken: apnsToken, accessToken: login.accessToken)
                        AppLogger.info("APNs token registered successfully after login", category: .auth)
                    } catch {
                        AppLogger.error("Failed to register APNs token after login: \(error.localizedDescription)", category: .auth)
                    }
                }
            } catch {
                AppLogger.error("Failed to register device after login: \(error.localizedDescription)", category: .auth)
                // Don't fail login if device registration fails
            }

            // Trigger timer sync after successful authentication
            AppLogger.info("Triggering timer sync after login", category: .auth)
            await TimerSyncManager.shared.syncTimerState()
        } catch {
            #if DEBUG
            print("[Auth] applyUser: backend call failed: \(error)")
            #endif
            // If backend call fails, ensure state reflects failure
            self.isSignedIn = false
            // Optionally sign out from Google to avoid partial auth state:
            // GIDSignIn.sharedInstance.signOut()
        }

        #if DEBUG
        print("[Auth] applyUser: end")
        #endif
    }

    private func applySignInResult(_ result: GIDSignInResult) async throws {
        #if DEBUG
        print("[Auth] applySignInResult: received Google result, forwarding user")
        #endif
        await applyUser(result.user)
    }
    #endif

    enum SignInError: Error {
        case noPresenter
        case sdkUnavailable
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
