import Foundation

public enum SignInError: Error, LocalizedError {
    case notConfigured
    case cancelled
    case failed(Error)

    public var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Google Sign-In is not configured"
        case .cancelled:
            return "Sign-in was cancelled"
        case .failed(let error):
            return "Sign-in failed: \(error.localizedDescription)"
        }
    }
}
