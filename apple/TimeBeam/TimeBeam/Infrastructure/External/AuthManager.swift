//
//  AuthManager.swift
//  TimeBeam
//
//  Created by Kayis Rahman on 03/11/25.
//

import Foundation
import Combine
import CryptoKit
import os

#if os(macOS)
import AppKit
#elseif os(iOS)
import AuthenticationServices
import UIKit
#endif

// Apple Sign-In helper removed - using ASWebAuthenticationSession instead 

/**
 * Configuration from Info.plist
 */
struct Configuration {
    let baseURL: URL

    static func fromInfoPlist() -> Configuration? {
        guard
            let dict = Bundle.main.infoDictionary,
            let base = dict["API_BASE_URL"] as? String,
            let url = URL(string: base)
        else { return nil }
        return Configuration(baseURL: url)
    }
}

@MainActor
final class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var isSignedIn: Bool = false
    @Published var displayName: String? = nil
    @Published var email: String? = nil

    // PKCE state and dedupe
    private var pkce: PKCE?
    private var lastProcessedAuthCode: String?
    private var isSigningIn = false

    init() {
        // Listen for OAuth completion notifications
        NotificationCenter.default.addObserver(self, selector: #selector(handleOAuthCompleted), name: NSNotification.Name("OAuthCompleted"), object: nil)
    }

    // MARK: - Public API

    func restoreSession() async {
        #if DEBUG
        print("[Auth] restoreSession: begin")
        #endif

        // Prefer backend access token as sign-in indicator (like working version)
        let backendToken = try? KeychainStore.loadString(.accessToken)
        let cachedName = try? KeychainStore.loadString(.userDisplayName)
        let cachedEmail = try? KeychainStore.loadString(.userEmail)

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
        // Revoke refresh tokens on backend
        guard let token = try? KeychainStore.loadString(.accessToken), !token.isEmpty else {
            await MainActor.run {
                self.isSignedIn = false
                self.displayName = nil
                self.email = nil
            }
            return
        }

        // Call backend to revoke tokens
        if let baseURL = Configuration.fromInfoPlist()?.baseURL {
            let api = ApiClient(baseURL: baseURL)
            await MainActor.run {
                self.isSignedIn = false
                self.displayName = nil
                self.email = nil
            }
            // TODO: Implement token revocation endpoint
        } else {
            await MainActor.run {
                self.isSignedIn = false
                self.displayName = nil
                self.email = nil
            }
        }
    }

    // Apple Sign-In disabled - requires provisioning profile capability

    // MARK: - Token Management

    func getValidAccessToken() -> String? {
        // Check if signed in first
        guard isSignedIn else {
            LoggerStore.auth.warning("getValidAccessToken called but not signed in")
            return nil
        }

        // Try to load from Keychain
        do {
            if let token = try KeychainStore.loadString(.accessToken), !token.isEmpty {
                // TODO: Add expiration check when token expiration is tracked
                // For now, assume token is valid if present
                LoggerStore.auth.debug("getValidAccessToken: Token found (length: \(token.count))")
                return token
            } else {
                LoggerStore.auth.warning("getValidAccessToken: No token found in Keychain")
            }
        } catch {
            LoggerStore.auth.error("getValidAccessToken: Failed to load token: \(error.localizedDescription)")
        }

        return nil
    }

    func signInWithGoogle() async throws {
        guard !isSigningIn else {
            #if DEBUG
            print("[Auth] signInWithGoogle: already in progress, ignoring duplicate call")
            #endif
            return
        }
        isSigningIn = true
        defer { isSigningIn = false }

        #if os(macOS)
        // macOS: Open Safari with OAuth URL (PKCE)
        guard let clientId = googleClientId() else {
            throw NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing GOOGLE_CLIENT_ID in Info.plist"])
        }
        let redirectUri = googleRedirectUri()
        let scope = "openid email profile"

        // Generate PKCE values
        let pkce = makePKCE()
        self.pkce = pkce

        // Persist PKCE for callback (in case app restarts between sign-in and callback)
        persistPKCE(pkce)

        var components = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectUri),
            URLQueryItem(name: "scope", value: scope),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "access_type", value: "offline"),
            URLQueryItem(name: "code_challenge", value: pkce.challenge),
            URLQueryItem(name: "code_challenge_method", value: pkce.method),
            URLQueryItem(name: "prompt", value: "consent")
        ]

        guard let authURL = components.url else {
            throw NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid OAuth URL"])
        }

        NSWorkspace.shared.open(authURL)

        #elseif os(iOS)
        // iOS: Use ASWebAuthenticationSession for OAuth
        guard let clientId = googleClientId() else {
            throw NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing GOOGLE_CLIENT_ID in Info.plist"])
        }
        let redirectUri = googleRedirectUri()
        let scope = "openid email profile"

        // Generate PKCE values
        let pkce = makePKCE()
        self.pkce = pkce

        // Persist PKCE for callback (in case app restarts between sign-in and callback)
        persistPKCE(pkce)

        var components = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectUri),
            URLQueryItem(name: "scope", value: scope),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "access_type", value: "offline"),
            URLQueryItem(name: "code_challenge", value: pkce.challenge),
            URLQueryItem(name: "code_challenge_method", value: pkce.method),
            URLQueryItem(name: "prompt", value: "consent")
        ]

        guard let authURL = components.url else {
            throw NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid OAuth URL"])
        }

        // Start OAuth session
        return try await performOAuthWithWebAuthentication(authURL: authURL)
        #endif
    }

    // Handle OAuth callback and complete sign-in
    func handleOAuthCallback(_ url: URL) async throws {
        #if DEBUG
        print("[Auth] handleOAuthCallback: OAuth callback received: \(url.absoluteString)")
        #endif

        // Restore PKCE if needed (for cross-app-restart scenarios)
        restorePKCEIfNeeded()

        // Extract authorization code from URL
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems,
              let codeItem = queryItems.first(where: { $0.name == "code" }),
              let code = codeItem.value else {
            throw SignInError.invalidRequest
        }

        // Prevent processing the same code twice
        if self.lastProcessedAuthCode == code {
            #if DEBUG
            print("[Auth] handleOAuthCallback: duplicate authorization code ignored")
            #endif
            return
        }
        self.lastProcessedAuthCode = code

        #if DEBUG
        print("[Auth] handleOAuthCallback: Authorization code received: \(code.prefix(20))...")
        #endif

        // Exchange authorization code for Google tokens
        let tokens = try await exchangeCodeForTokens(code)

        // Decode user info from ID token
        let userInfo = try decodeUserInfoFromIdToken(tokens.idToken)

        // Complete sign-in with backend
        await completeOAuthSignIn(email: userInfo.email, oauthName: userInfo.name)
    }

    private func exchangeCodeForTokens(_ code: String) async throws -> (idToken: String, accessToken: String) {
        guard let clientId = googleClientId() else {
            #if DEBUG
            print("[Auth] Missing GOOGLE_CLIENT_ID in Info.plist")
            #endif
            throw SignInError.invalidRequest
        }
        let redirectUri = googleRedirectUri()

        guard let verifier = pkce?.verifier else {
            #if DEBUG
            print("[Auth] Missing PKCE verifier; cannot complete token exchange")
            #endif
            throw SignInError.invalidRequest
        }

        var request = URLRequest(url: URL(string: "https://oauth2.googleapis.com/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        var body = URLComponents()
        body.queryItems = [
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectUri),
            URLQueryItem(name: "grant_type", value: "authorization_code"),
            URLQueryItem(name: "code_verifier", value: verifier)
        ]
        request.httpBody = body.percentEncodedQuery?.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as? HTTPURLResponse

        #if DEBUG
        print("[Auth] Token exchange response status: \(httpResponse?.statusCode ?? 0)")
        if let text = String(data: data, encoding: .utf8) {
            print("[Auth] Token exchange response body: \(text)")
        }
        #endif

        guard httpResponse?.statusCode == 200 else {
            print("[Auth] Token exchange failed: HTTP \(httpResponse?.statusCode ?? 0)")
            throw SignInError.invalidResponse
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("[Auth] Token exchange: failed to parse JSON")
            throw SignInError.invalidResponse
        }

        #if DEBUG
        print("[Auth] OAuth response keys: \(json.keys.joined(separator: ", "))")
        #endif

        guard let idToken = json["id_token"] as? String,
              let accessToken = json["access_token"] as? String else {
            #if DEBUG
            print("[Auth] OAuth response missing id_token or access_token")
            #endif
            throw SignInError.invalidResponse
        }

        // Clear PKCE state after successful exchange
        self.pkce = nil
        clearPersistedPKCE()

        return (idToken: idToken, accessToken: accessToken)
    }

    private func decodeUserInfoFromIdToken(_ idToken: String) throws -> (email: String, name: String) {
        // JWT format: header.payload.signature
        let parts = idToken.split(separator: ".")
        guard parts.count >= 2 else { throw SignInError.invalidResponse }

        let payload = String(parts[1])
        // Add padding if needed
        let paddedPayload = payload + String(repeating: "=", count: (4 - payload.count % 4) % 4)
        guard let payloadData = Data(base64Encoded: paddedPayload),
              let payloadJson = try JSONSerialization.jsonObject(with: payloadData) as? [String: Any],
              let email = payloadJson["email"] as? String,
              let name = payloadJson["name"] as? String else {
            throw SignInError.invalidResponse
        }

        return (email: email, name: name)
    }

    private func googleClientId() -> String? {
        if let dict = Bundle.main.infoDictionary,
            let clientId = dict["GOOGLE_CLIENT_ID"] as? String,
            !clientId.isEmpty {
            return clientId
        }
        return nil
    }

    private func googleClientSecret() -> String? {
        if let dict = Bundle.main.infoDictionary,
            let secret = dict["GOOGLE_CLIENT_SECRET"] as? String,
            !secret.isEmpty {
            return secret
        }
        return nil
    }

    private func googleRedirectUri() -> String? {
        if let dict = Bundle.main.infoDictionary,
            let redirectUri = dict["GOOGLE_REDIRECT_URI"] as? String,
            !redirectUri.isEmpty {
            return redirectUri
        }
        // Fallback to platform-specific default
        #if os(iOS)
        return "com.sparkage.time-beam.ios://"
        #elseif os(macOS)
        return "com.sparkage.time-beam://"
        #endif
    }

    @objc private func handleOAuthCompleted() {
        // This method is called when OAuth completes, but we need the authorization code
        // The code should be passed through a different mechanism
        // For now, we'll implement a basic completion
        Task {
            await completeOAuthSignIn(email: "oauth@example.com", oauthName: "OAuth User")
        }
    }

    private func completeOAuthSignIn(email: String, oauthName: String) async {
        // Use backend user info if available, otherwise fallback to OAuth name
        var displayName = oauthName
        var userEmail = email

        do {
            // Call backend login with the email (like the working implementation)
            guard let baseURL = Configuration.fromInfoPlist()?.baseURL else {
                #if DEBUG
                print("[Auth] completeOAuthSignIn: missing API configuration")
                #endif
                await MainActor.run {
                    self.isSignedIn = false
                }
                return
            }

            let api = ApiClient(baseURL: baseURL)

            #if DEBUG
            print("[DEBUG] API Base URL: \(baseURL)")
            print("[DEBUG] Login endpoint: \(baseURL)/auth/login")
            print("[DEBUG] User email: \(redactEmail(email))")
            print("[Auth] completeOAuthSignIn: calling backend login for email=\(redactEmail(email))")
            #endif

            let login = try await api.login(email: email)

            #if DEBUG
            print("[Auth] completeOAuthSignIn: backend login success (accessTokenLen=\(login.accessToken.count))")
            #endif

            // Update with backend user info if available; prefer a human-readable name
            let backendName = login.user?.displayName
            let oauthHumanName = oauthName
            var chosenName = backendName ?? oauthHumanName
            // If backend name looks like a handle (no spaces) and OAuth name looks like a real name (has spaces), prefer OAuth name
            if let backendName = backendName, !backendName.contains(" "), oauthHumanName.contains(" ") {
                chosenName = oauthHumanName
            }
            displayName = chosenName
            userEmail = login.user?.email ?? email

            // Store tokens and user info in Keychain
            try KeychainStore.saveString(login.accessToken, for: .accessToken)
            try KeychainStore.saveString(userEmail, for: .userEmail)
            try KeychainStore.saveString(displayName, for: .userDisplayName)

            // Store in UserDefaults for session restoration
            UserDefaults.standard.set(true, forKey: "hasAuthToken")

            // Update UI state
            await MainActor.run {
                self.isSignedIn = true
                self.email = userEmail
                self.displayName = displayName
            }

            #if DEBUG
            print("[Auth] completeOAuthSignIn: authentication completed successfully")
            #endif

        } catch {
            #if DEBUG
            print("[Auth] completeOAuthSignIn: backend login failed: \(error)")
            #endif

            // If backend fails, still allow local sign-in for development
            await MainActor.run {
                self.isSignedIn = true
                self.email = userEmail
                self.displayName = displayName
            }
            UserDefaults.standard.set(true, forKey: "hasAuthToken")
        }
    }

    private func redactEmail(_ email: String) -> String {
        guard let at = email.firstIndex(of: "@") else { return email.isEmpty ? "<empty>" : "<redacted>" }
        let name = email[..<at]
        let domain = email[email.index(after: at)...]
        let shown = name.prefix(2)
        return "\(shown)***@\(domain)"
    }

    #if os(iOS)
    private func performOAuthWithWebAuthentication(authURL: URL) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            // Create presentation context provider that will be retained
            let presentationProvider = OAuthPresentationContextProvider()

            let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: "com.googleusercontent.apps.512741716533-iks9gube8oh8f0gopnmc3v72pe6u3p5m") { callbackURL, error in
                if let error = error {
                    self.pkce = nil
                    self.clearPersistedPKCE()
                    continuation.resume(throwing: error)
                    return
                }

                guard let callbackURL = callbackURL else {
                    continuation.resume(throwing: NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No callback URL received"]))
                    return
                }

                // Handle the callback asynchronously
                Task {
                    do {
                        try await self.handleOAuthCallback(callbackURL)
                        continuation.resume()
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }

            // Ensure we're on the main thread for UI operations
            let setupAndStartSession = {
                // Set presentation context provider BEFORE starting
                session.presentationContextProvider = presentationProvider

                // Double-check that it's set
                guard session.presentationContextProvider != nil else {
                    continuation.resume(throwing: NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to set presentation context provider"]))
                    return
                }

                // Now start the session
                session.start()
            }

            if Thread.isMainThread {
                setupAndStartSession()
            } else {
                DispatchQueue.main.async(execute: setupAndStartSession)
            }
        }
    }
    #endif

    private func makePKCE() -> PKCE {
        let verifier = randomCodeVerifier()
        let challenge = codeChallenge(for: verifier)
        return PKCE(verifier: verifier, challenge: challenge)
    }

    private func randomCodeVerifier(length: Int = 64) -> String {
        let allowed = Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
        var result = ""
        result.reserveCapacity(length)
        for _ in 0..<length {
            if let random = allowed.randomElement() {
                result.append(random)
            }
        }
        return result
    }

    private func codeChallenge(for verifier: String) -> String {
        let data = Data(verifier.utf8)
        let hash = SHA256.hash(data: data)
        return base64URLEncode(Data(hash))
    }

    private func base64URLEncode(_ data: Data) -> String {
        let base64 = data.base64EncodedString()
        return base64
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    // PKCE persistence methods for cross-app-restart scenarios
    private func persistPKCE(_ pkce: PKCE) {
        let pkceData = try? JSONEncoder().encode(pkce)
        UserDefaults.standard.set(pkceData, forKey: "auth_pkce_state")
    }

    private func loadPersistedPKCE() -> PKCE? {
        guard let data = UserDefaults.standard.data(forKey: "auth_pkce_state") else { return nil }
        return try? JSONDecoder().decode(PKCE.self, from: data)
    }

    private func clearPersistedPKCE() {
        UserDefaults.standard.removeObject(forKey: "auth_pkce_state")
    }

    // Load PKCE from persistence if needed
    private func restorePKCEIfNeeded() {
        if self.pkce == nil, let persisted = loadPersistedPKCE() {
            self.pkce = persisted
            #if DEBUG
            print("[Auth] Restored PKCE from persistence")
            #endif
        }
    }
}

#if os(iOS)
class OAuthPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // Use window from connected scenes (iOS 13+)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
            return window
        }
        
        // Fallback: get first window from first scene
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            return window
        }

        // If all else fails, this will cause a runtime error, but that's better than silent failure
        fatalError("Unable to find a suitable presentation anchor for ASWebAuthenticationSession")
    }
}
#endif
