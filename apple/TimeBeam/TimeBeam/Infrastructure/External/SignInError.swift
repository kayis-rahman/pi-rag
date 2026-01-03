import Foundation

public enum SignInError: Error, LocalizedError {
    case notConfigured
    case cancelled
    case failed(Error)
    case invalidRequest
    case invalidResponse

    public var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Google Sign-In is not configured"
        case .cancelled:
            return "Sign-in was cancelled"
        case .failed(let error):
            return "Sign-in failed: \(error.localizedDescription)"
        case .invalidRequest:
            return "Invalid request to authentication server"
        case .invalidResponse:
            return "Invalid response from authentication server"
        }
    }
}
