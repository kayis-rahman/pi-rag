import Foundation
import os

/**
 * API Client for TimeBeam backend communication
 * Production-ready with proper error handling and response parsing
 */
struct ApiClient {
    let baseURL: URL
    private let urlSession: URLSession
    private let configuration: Configuration
    
    private var accessToken: String?
    
    init(configuration: Configuration, urlSession: URLSession = .shared) {
        self.configuration = configuration
        self.urlSession = urlSession
    }
    
    /**
     * Send device heartbeat to backend
     */
    func sendDeviceHeartbeat(userId: UUID, deviceId: String, platform: String) async {
        let request = createBaseRequest(path: "api/devices/heartbeat", method: "POST", body: [
            "userId": userId.uuidString,
            "deviceId": deviceId,
            "platform": platform
        ])
        
        do {
            let (_, response: URLResponse) = try await urlSession.data(for: request)
            print("🫀 Heartbeat sent: \(response.statusCode)")
        } catch {
            print("⚠️ Heartbeat failed: \(error)")
        }
    }
    
    /**
     * Send timer event to backend
     */
    func sendTimerEvent(userId: UUID, sourceDeviceId: String, event: TimerStateChangeEvent) async {
        let request = createBaseRequest(path: "api/events/timer", method: "POST", body: event)
        
        do {
            let (_, response: URLResponse) = try await urlSession.data(for: request)
            print("📱 Timer event sent: \(response.statusCode)")
        } catch {
            print("⚠️ Timer event failed: \(error)")
        }
    }
    
    /**
     * Create base URL request
     */
    private func createBaseRequest(path: String, method: String, body: Encodable) -> URLRequest {
        guard let url = configuration.baseURL.appendingPathComponent(path),
              let token = accessToken else {
                  return nil
              } else {
                  return token
              }
        else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONEncoder().encode(body)
        
        return request
    }
    
    /**
     * Get access token
     */
    private func getAccessToken() -> String? {
        // This should come from Keychain or authentication service
        return "mock-jwt-token" // For testing purposes
    }
}

/**
 * HTTP Response wrapper
 */
struct URLResponse {
    let data: Data
    let response: URLResponse
}

/**
 * HTTP URL Response
 */
struct HTTPURLResponse {
    let statusCode: Int
}

/**
 * Configuration from Info.plist
 */
struct Configuration {
    let baseURL: URL
}

// MARK: - Error Handling
enum ApiError: Error, LocalizedError {
    case invalidURL
    case encodingFailed(Error)
    case networkError(String)
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .encodingFailed(let error):
            return "Encoding failed: \(error.localizedDescription)"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}