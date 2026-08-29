import Foundation
import AuthenticationServices

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

#if os(iOS) || os(macOS)
@MainActor
final class AppleSignInCoordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    static let shared = AppleSignInCoordinator()

    struct Account {
        let userIdentifier: String
        let displayName: String?
        let email: String?
    }

    private var continuation: CheckedContinuation<Account, Error>?

    func signIn() async throws -> Account {
        guard continuation == nil else {
            throw SignInError.failed(NSError(domain: "AppleSignIn", code: 1))
        }

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            finish(.failure(SignInError.invalidResponse))
            return
        }

        let formatter = PersonNameComponentsFormatter()
        let displayName = credential.fullName.map { formatter.string(from: $0) }
        finish(.success(Account(
            userIdentifier: credential.user,
            displayName: displayName,
            email: credential.email
        )))
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        let nsError = error as NSError
        if nsError.domain == ASAuthorizationError.errorDomain,
           nsError.code == ASAuthorizationError.canceled.rawValue {
            finish(.failure(SignInError.cancelled))
        } else {
            finish(.failure(SignInError.appleSignInFailed(error)))
        }
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        #if os(iOS)
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow) ?? UIWindow()
        #else
        return NSApplication.shared.keyWindow ?? NSWindow()
        #endif
    }

    private func finish(_ result: Result<Account, Error>) {
        let continuation = continuation
        self.continuation = nil
        continuation?.resume(with: result)
    }
}
#endif
