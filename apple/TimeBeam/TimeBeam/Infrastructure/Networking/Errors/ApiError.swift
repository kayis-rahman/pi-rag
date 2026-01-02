import Foundation

/// API error types for network and HTTP errors
enum ApiError: Error {
    case invalidURL
    case encodingFailed(Error)
    case networkError(String)
    case unauthorized
    case serverError(Int, String?)

    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .encodingFailed(let error):
            return "Encoding failed: \(error.localizedDescription)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .unauthorized:
            return "Unauthorized - Please log in again"
        case .serverError(let code, let message):
            if let msg = message {
                return "Server error (\(code)): \(msg)"
            }
            return "Server error (\(code))"
        }
    }
}
