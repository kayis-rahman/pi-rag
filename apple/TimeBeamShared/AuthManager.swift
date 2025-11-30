import Foundation
import Combine

@MainActor
final class AuthManager: ObservableObject {
    @Published var isSignedIn: Bool = false
    @Published var displayName: String? = nil
    @Published var email: String? = nil

    func restoreSession() async {
        let token = try? KeychainStore.loadString(.idToken)
        let cachedName = try? KeychainStore.loadString(.userDisplayName)
        let cachedEmail = try? KeychainStore.loadString(.userEmail)

        self.isSignedIn = (token?.isEmpty == false)
        if let name = cachedName, !name.isEmpty { self.displayName = name }
        if let mail = cachedEmail, !mail.isEmpty { self.email = mail }
    }

    func signOut() async {
        try? KeychainStore.clear(.idToken)
        try? KeychainStore.clear(.accessToken)
        try? KeychainStore.clear(.userDisplayName)
        try? KeychainStore.clear(.userEmail)
        self.isSignedIn = false
        self.displayName = nil
        self.email = nil

        await WatchConnectivityManager.shared?.pushAuthStateToCounterpart(
            isSignedIn: false,
            displayName: nil,
            email: nil
        )
    }
}

#if os(iOS)
import AuthenticationServices
// If you adopt GoogleSignIn SDK, also: import GoogleSignIn

extension AuthManager {
    func signInWithGoogle(presentingAnchor: ASPresentationAnchor?) async throws {
        // TODO: Replace with real Google Sign-In flow (SDK or ASWebAuthenticationSession)

        // Temporary stub for wiring:
        let idToken = "stub-id-token"
        let accessToken = "stub-access-token"
        let name = "Time Beam User"
        let mail = "user@example.com"

        try KeychainStore.saveString(idToken, for: .idToken)
        try KeychainStore.saveString(accessToken, for: .accessToken)
        try KeychainStore.saveString(name, for: .userDisplayName)
        try KeychainStore.saveString(mail, for: .userEmail)

        self.isSignedIn = true
        self.displayName = name
        self.email = mail

        await WatchConnectivityManager.shared?.pushAuthStateToCounterpart(
            isSignedIn: true,
            displayName: name,
            email: mail
        )
    }
}
#endif
