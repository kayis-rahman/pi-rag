import Foundation

/**
 * API Client for TimeBeam backend communication
 * Production-ready with proper error handling and response parsing
 */
public struct ApiClient {
    let baseURL: URL
    private let urlSession: URLSession
    private var accessToken: String?
    
    /// Callback for authentication failures
    var onAuthenticationFailure: (() -> Void)?
    
    /**
     * Configuration from Info.plist
     * This is defined here to allow ApiClient.Configuration.fromInfoPlist() pattern used in codebase
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
    
    init(baseURL: URL) {
        self.baseURL = baseURL
        self.urlSession = URLSession.shared
        self.accessToken = nil
    }
    
    // MARK: - Singleton Instance
    
    private static var _shared: ApiClient?
    
    public static var shared: ApiClient {
        if let instance = _shared {
            return instance
        }
        
        guard let config = ApiClient.Configuration.fromInfoPlist() else {
            fatalError("ApiClient.shared: Configuration not found - API_BASE_URL must be set in Info.plist")
        }
        
        let instance = ApiClient(baseURL: config.baseURL)
        _shared = instance
        return instance
    }
    
    /**
     * Device statistics for account management
     */
    
    /**
     * Device registration DTO
     */
    
    /**
     * Task DTO
     */
    
    /**
     * Timer State DTO
     */
    /**
     * Timer Action DTO - Event-based synchronization
     * Contains only action type and static metadata (no continuously changing fields)
     */
    
    
    // MARK: - Private Helpers
    
    /* private func createRequest(path: String, method: String, body: Any?, accessToken: String?) -> URLRequest? {
     guard let token = accessToken ?? self.accessToken else {
     return nil
     }
     
     guard let url = URL(string: "\(baseURL.absoluteString)/\(path)") else {
     return nil
     }
     
     var request = URLRequest(url: url)
     request.httpMethod = method
     request.setValue("application/json", forHTTPHeaderField: "Content-Type")
     request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
     
     if let body = body {
     request.httpBody = try? JSONSerialization.data(withJSONObject: body)
     }
     
     return request
     }
     */
    
    /**
     * Create base URL request
     */
    private func createBaseRequest(path: String, method: String, body: Encodable, accessToken: String? = nil) -> URLRequest? {
        let token = accessToken ?? self.accessToken
        guard let token = token else {
            print("❌ ApiClient: No access token available")
            return nil
        }
        
        let url = baseURL.appendingPathComponent(path)
        print("✅ ApiClient: Creating request to URL: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        print("🔐 ApiClient: Authorization header set: Bearer \(token.prefix(20))...")
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
            print("✅ ApiClient: Request body encoded successfully")
        } catch {
            print("❌ ApiClient: Failed to encode request body: \(error)")
            return nil
        }
        
        print("📋 ApiClient: Final request headers: \(request.allHTTPHeaderFields ?? [:])")
        
        return request
    }
    
    /**
     * Get access token
     */
    func getAccessToken() -> String? {
        // TODO: Get real access token from Keychain
        // For now, return nil
        return nil
    }
    
    // MARK: - Auth Methods
    
    
    
    struct RefreshResponse: Codable {
        let accessToken: String
        let refreshToken: String
    }

    func refreshToken(refreshToken: String) async throws -> RefreshResponse {
        let url = baseURL.appendingPathComponent("api/auth/refresh")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(refreshToken)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw ApiError.authenticationFailure
        }
        return try JSONDecoder().decode(RefreshResponse.self, from: data)
    }

    func login(email: String) async throws -> LoginResponse {
        let url = baseURL.appendingPathComponent("api/auth/login")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["email": email]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw ApiError.networkError("Login failed with status: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
        }
        
        return try JSONDecoder().decode(LoginResponse.self, from: data)
    }
    
    
    
    // MARK: - Response Types
    
    
    // MARK: - Session Methods
    
    func startSession(kind: String, taskId: UUID?, accessToken: String) async throws -> SessionRecordDto {
         var url = baseURL.appendingPathComponent("api/sessions/start")
         var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "kind", value: kind)]
        if let taskId = taskId {
            components?.queryItems?.append(URLQueryItem(name: "taskId", value: taskId.uuidString))
        }
        if let finalURL = components?.url {
            url = finalURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ApiError.networkError("Invalid response type")
        }
        guard httpResponse.statusCode == 201 || httpResponse.statusCode == 200 else {
            throw ApiError.networkError("Start session failed with status: \(httpResponse.statusCode)")
        }
        
        return try JSONDecoder().decode(SessionRecordDto.self, from: data)
    }
    
    func stopSession(id: UUID, accessToken: String) async throws {
        guard let request = createBaseRequest(path: "api/sessions/\(id)/stop", method: "POST", body: EmptyResponse(success: true), accessToken: accessToken) else {
            throw ApiError.networkError("Failed to create request")
        }
        let (_, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ApiError.networkError("Invalid response type")
        }
        guard httpResponse.statusCode == 200 else {
            throw ApiError.networkError("Stop session failed with status: \(httpResponse.statusCode)")
        }
    }
    
    // MARK: - Session Management Methods (Added for iOS timer sync)
    
    
    func fetchSessions(accessToken: String) async throws -> [SessionRecordDto] {
        let url = baseURL.appendingPathComponent("api/sessions")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ApiError.networkError("Invalid response type")
        }
        guard httpResponse.statusCode == 200 else {
            throw ApiError.networkError("Fetch sessions failed with status: \(httpResponse.statusCode)")
        }
        
        return try JSONDecoder().decode([SessionRecordDto].self, from: data)
    }
    
    /**
     * Register device with backend
     */
    func registerDevice(_ registration: DeviceRegistrationDto, accessToken: String) async throws {
        guard let request =  createBaseRequest(path: "api/devices/register", method: "POST", body: registration, accessToken: accessToken) else {
            throw ApiError.networkError("Failed to create request")
        }
        let (_, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ApiError.networkError("Invalid response type")
        }
        guard httpResponse.statusCode == 200 else {
            throw ApiError.networkError("Register device failed with status: \(httpResponse.statusCode)")
        }
    }
    
    func pushTimerState(_ state: TimerStateDto, accessToken: String) async throws {
        guard let request = createBaseRequest(path: "api/sessions/timer/state", method: "POST", body: state, accessToken: accessToken) else {
            throw ApiError.networkError("Failed to create request")
        }
        let (_, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ApiError.networkError("Invalid response type")
        }
        guard httpResponse.statusCode == 200 else {
            throw ApiError.networkError("Push timer state failed with status: \(httpResponse.statusCode)")
        }
    }
    
    func pullTimerState(accessToken: String) async throws -> TimerStateDto? {
        let url = baseURL.appendingPathComponent("api/sessions/timer/state")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ApiError.networkError("Invalid response type")
        }
        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 204 else {
            throw ApiError.networkError("Pull timer state failed with status: \(httpResponse.statusCode)")
        }
        
        if httpResponse.statusCode == 204 {
            return nil // No content
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            if let unixSeconds = try? container.decode(Double.self) {
                return Date(timeIntervalSince1970: unixSeconds)
            }
            let str = try container.decode(String.self)
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = iso.date(from: str) { return date }
            iso.formatOptions = [.withInternetDateTime]
            if let date = iso.date(from: str) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date: \(str)")
        }
        return try decoder.decode(TimerStateDto.self, from: data)
    }

    func pushTimerAction(_ action: TimerActionDto, accessToken: String) async throws {
        guard let request =  createBaseRequest(path: "api/sessions/timer/action", method: "POST", body: action, accessToken: accessToken) else {
            throw ApiError.networkError("Failed to create request")
        }
        let (_, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ApiError.networkError("Invalid response type")
        }
        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            throw ApiError.networkError("Push timer action failed with status: \(httpResponse.statusCode)")
        }
    }
    
    func updateApnsToken(deviceId: String, apnsToken: String, accessToken: String) async throws {
        print("[APNs Token] Starting APNs token update for device: \(deviceId)")
        let body = ["deviceId": deviceId, "apnsToken": apnsToken]
        guard let request = createBaseRequest(path: "/api/sessions/devices/apns-token", method: "POST", body: body, accessToken: accessToken) else {
            throw ApiError.networkError("Failed to create request")
        }
        let (_, response) =  try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ApiError.networkError("Invalid response type")
        }
        guard httpResponse.statusCode == 200 else {
            throw ApiError.networkError("Update APNs token failed with status: \(httpResponse.statusCode)")
        }
        
        print("[APNs Token] Successfully updated APNs token for device: \(deviceId)")
    }
    
    // MARK: - Device Methods
    
    func getDeviceStats(accessToken: String) async throws -> DeviceStats {
        let url = baseURL.appendingPathComponent("api/devices/stats")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) =  try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ApiError.networkError("Invalid response type")
        }
        guard httpResponse.statusCode == 200 else {
            throw ApiError.networkError("Get device stats failed with status: \(httpResponse.statusCode)")
        }
        
        return try JSONDecoder().decode(DeviceStats.self, from: data)
    }
    
    // MARK: - Task Methods
    
    
    
    func createTask(_ request: TaskCreateRequest, accessToken: String) async throws -> TaskDto {
        guard let req = createBaseRequest(path: "api/tasks", method: "POST", body: request, accessToken: accessToken) else {
            throw ApiError.networkError("Failed to create request")
        }
        let (data, response) = try await urlSession.data(for: req)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ApiError.networkError("Invalid response type")
        }
        guard httpResponse.statusCode == 201 || httpResponse.statusCode == 200 else {
            throw ApiError.networkError("Create task failed with status: \(httpResponse.statusCode)")
        }
        
        return try JSONDecoder().decode(TaskDto.self, from: data)
    }
    
    func fetchTasks(accessToken: String) async throws -> [TaskDto] {
        let url = baseURL.appendingPathComponent("api/tasks")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ApiError.networkError("Invalid response type")
        }
        guard httpResponse.statusCode == 200 else {
            throw ApiError.networkError("Fetch tasks failed with status: \(httpResponse.statusCode)")
        }
        
        return try JSONDecoder().decode([TaskDto].self, from: data)
    }
    
    func fetchActiveTasks(accessToken: String) async throws -> [TaskDto] {
        // Assuming active tasks are fetched with a query parameter
        var components = URLComponents(url: baseURL.appendingPathComponent("api/tasks"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "status", value: "active")]
        guard let url = components?.url else {
            throw ApiError.networkError("Invalid URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ApiError.networkError("Invalid response type")
        }
        guard httpResponse.statusCode == 200 else {
            throw ApiError.networkError("Fetch active tasks failed with status: \(httpResponse.statusCode)")
        }
        
        return try JSONDecoder().decode([TaskDto].self, from: data)
    }
    
    func fetchTask(id: UUID, accessToken: String) async throws -> TaskDto {
        let url = baseURL.appendingPathComponent("tasks/\(id)")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ApiError.networkError("Invalid response type")
        }
        guard httpResponse.statusCode == 200 else {
            throw ApiError.networkError("Fetch task failed with status: \(httpResponse.statusCode)")
        }
        
        return try JSONDecoder().decode(TaskDto.self, from: data)
    }
    
    func updateTask(id: UUID, _ request: TaskUpdateRequest, accessToken: String) async throws -> TaskDto {
        guard let req = createBaseRequest(path: "tasks/\(id)", method: "PUT", body: request, accessToken: accessToken) else {
            throw ApiError.networkError("Failed to create request")
        }
        let (data, response) = try await urlSession.data(for: req)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ApiError.networkError("Invalid response type")
        }
        guard httpResponse.statusCode == 200 else {
            throw ApiError.networkError("Update task failed with status: \(httpResponse.statusCode)")
        }
        
        return try JSONDecoder().decode(TaskDto.self, from: data)
    }
    
    func deleteTask(id: UUID, accessToken: String) async throws {
        let url = baseURL.appendingPathComponent("tasks/\(id)")
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (_, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ApiError.networkError("Invalid response type")
        }
        guard httpResponse.statusCode == 204 || httpResponse.statusCode == 200 else {
            throw ApiError.networkError("Delete task failed with status: \(httpResponse.statusCode)")
        }
    }
    
    func postSession(_ session: SessionRecordDto, accessToken: String) async throws {
        guard let request = createBaseRequest(path: "api/sessions", method: "POST", body: session, accessToken: accessToken) else {
            throw ApiError.networkError("Failed to create request")
        }
        let (_, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ApiError.networkError("Invalid response type")
        }
        guard httpResponse.statusCode == 201 || httpResponse.statusCode == 200 else {
            throw ApiError.networkError("Post session failed with status: \(httpResponse.statusCode)")
        }
    }
    
    // MARK: - Enhanced Error Handling
    enum ApiError: Error, LocalizedError {
        case invalidURL
        case encodingFailed(Error)
        case networkError(String)
        case authenticationFailure
        case timeoutError(String)
        case retryExceeded(String)
        case serverError(Int, String)

        var errorDescription: String {
            switch self {
            case .invalidURL:
                return "Invalid API URL"
            case .encodingFailed(let error):
                return "Encoding failed: \(error.localizedDescription)"
            case .networkError(let message):
                return "Network error: \(message)"
            case .authenticationFailure:
                return "Authentication failure"
            case .timeoutError(let message):
                return "Request timeout: \(message)"
            case .retryExceeded(let message):
                return "Retry limit exceeded: \(message)"
            case .serverError(let statusCode, let message):
                return "Server error \(statusCode): \(message)"
            }
        }
    }
}

