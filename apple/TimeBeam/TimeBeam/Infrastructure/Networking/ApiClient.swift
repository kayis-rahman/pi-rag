import Foundation

/**
 * API Client for TimeBeam backend communication
 * Production-ready with proper error handling and response parsing
 */
struct ApiClient {
    let baseURL: URL
    private let urlSession: URLSession
    private var accessToken: String?

    /// Callback for authentication failures
    var onAuthenticationFailure: (() -> Void)?

    init(baseURL: URL, urlSession: URLSession = .shared) {
        self.baseURL = baseURL
        self.urlSession = urlSession
        self.accessToken = nil
    }

    /**
     * Device statistics for account management
     */
    struct DeviceStats: Codable {
        let totalDevices: Int
        let activeDevices: Int
        let iosDevices: Int
        let macDevices: Int
        let watchosDevices: Int
        let lastSyncTime: Date
    }

    /**
     * Task DTO
     */
    struct TaskDto: Codable {
        let id: UUID
        let userId: UUID
        let title: String
        let description: String?
        let status: String
        let createdAt: Date
        let updatedAt: Date
    }

    /**
     * Timer State DTO
     */
    struct TimerStateDto: Codable {
        let phase: String?
        let remainingSeconds: Int?
        let isRunning: Bool?
        let workDuration: Int?
        let breakDuration: Int?
        let longBreakDuration: Int?
        let autoStartNextSession: Bool?
        let shortBreaksCompleted: Int?
        let totalDuration: Int?
        let lastModifiedTimestamp: Double?
        let deviceId: String?

        init(
            phase: String? = nil,
            remainingSeconds: Int? = nil,
            isRunning: Bool? = nil,
            workDuration: Int? = nil,
            breakDuration: Int? = nil,
            longBreakDuration: Int? = nil,
            autoStartNextSession: Bool? = nil,
            shortBreaksCompleted: Int? = nil,
            totalDuration: Int? = nil,
            lastModifiedTimestamp: Double? = nil,
            deviceId: String? = nil
        ) {
            self.phase = phase
            self.remainingSeconds = remainingSeconds
            self.isRunning = isRunning
            self.workDuration = workDuration
            self.breakDuration = breakDuration
            self.longBreakDuration = longBreakDuration
            self.autoStartNextSession = autoStartNextSession
            self.shortBreaksCompleted = shortBreaksCompleted
            self.totalDuration = totalDuration
            self.lastModifiedTimestamp = lastModifiedTimestamp
            self.deviceId = deviceId
        }
     }

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

    struct User: Codable {
        let id: UUID
        let email: String
        let displayName: String
    }

    struct LoginResponse: Codable {
        let accessToken: String
        let user: User?
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

    struct EmptyResponse: Codable {
        let success: Bool
    }

// MARK: - Session Methods

      struct SessionRecordDto: Codable {
          let id: UUID
          let userId: UUID?
          let startedAt: Date
          let durationSeconds: Int
          let kind: String
          let taskId: UUID?

          init(id: UUID, startedAt: Date, duration: TimeInterval, kind: String) {
              self.id = id
              self.userId = nil // Will be set by server
              self.startedAt = startedAt
              self.durationSeconds = Int(duration)
              self.kind = kind.uppercased()
              self.taskId = nil
          }
      }

      func startSession(kind: String, taskId: UUID?, accessToken: String) async throws -> SessionRecordDto {
          var url = baseURL.appendingPathComponent("sessions/start")
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
          guard let request = try createBaseRequest(path: "sessions/\(id)/stop", method: "POST", body: EmptyResponse(success: true), accessToken: accessToken) else {
              throw ApiError.networkError("Failed to create request")
          }
          let (data, response) = try await urlSession.data(for: request)

          guard let httpResponse = response as? HTTPURLResponse else {
              throw ApiError.networkError("Invalid response type")
          }
          guard httpResponse.statusCode == 200 else {
              throw ApiError.networkError("Stop session failed with status: \(httpResponse.statusCode)")
          }
      }
      
      // MARK: - Session Management Methods (Added for iOS timer sync)
      
      func postSession(_ session: SessionRecordDto, accessToken: String) async throws {
          guard let request = try createBaseRequest(path: "sessions", method: "POST", body: session, accessToken: accessToken) else {
              throw ApiError.networkError("Failed to create request")
          }
          let (data, response) = try await urlSession.data(for: request)

          guard let httpResponse = response as? HTTPURLResponse else {
              throw ApiError.networkError("Invalid response type")
          }
          guard httpResponse.statusCode == 201 || httpResponse.statusCode == 200 else {
              throw ApiError.networkError("Post session failed with status: \(httpResponse.statusCode)")
          }
      }
      
      func fetchSessions(accessToken: String) async throws -> [SessionRecordDto] {
          let url = baseURL.appendingPathComponent("sessions")
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

    func pushTimerState(_ state: TimerStateDto, accessToken: String) async throws {
        guard let request = try createBaseRequest(path: "sessions/timer/state", method: "POST", body: state, accessToken: accessToken) else {
            throw ApiError.networkError("Failed to create request")
        }
        let (data, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ApiError.networkError("Invalid response type")
        }
        guard httpResponse.statusCode == 200 else {
            throw ApiError.networkError("Push timer state failed with status: \(httpResponse.statusCode)")
        }
    }

    func pullTimerState(accessToken: String) async throws -> TimerStateDto? {
        let url = baseURL.appendingPathComponent("sessions/timer/state")
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

        return try JSONDecoder().decode(TimerStateDto.self, from: data)
    }

    func updateApnsToken(deviceId: String, apnsToken: String, accessToken: String) async throws {
        let body = ["deviceId": deviceId, "apnsToken": apnsToken]
        guard let request = try createBaseRequest(path: "sessions/devices/apns-token", method: "POST", body: body, accessToken: accessToken) else {
            throw ApiError.networkError("Failed to create request")
        }
        let (data, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ApiError.networkError("Invalid response type")
        }
        guard httpResponse.statusCode == 200 else {
            throw ApiError.networkError("Update APNs token failed with status: \(httpResponse.statusCode)")
        }
    }

    // MARK: - Device Methods

    func getDeviceStats(accessToken: String) async throws -> DeviceStats {
        let url = baseURL.appendingPathComponent("devices/stats")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ApiError.networkError("Invalid response type")
        }
        guard httpResponse.statusCode == 200 else {
            throw ApiError.networkError("Get device stats failed with status: \(httpResponse.statusCode)")
        }

        return try JSONDecoder().decode(DeviceStats.self, from: data)
    }

    // MARK: - Task Methods

    struct TaskCreateRequest: Codable {
        let title: String
        let description: String?
    }

    struct TaskUpdateRequest: Codable {
        let title: String?
        let description: String?
        let status: String?
    }

    func createTask(_ request: TaskCreateRequest, accessToken: String) async throws -> TaskDto {
        guard let req = try createBaseRequest(path: "tasks", method: "POST", body: request, accessToken: accessToken) else {
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
        let url = baseURL.appendingPathComponent("tasks")
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
        var components = URLComponents(url: baseURL.appendingPathComponent("tasks"), resolvingAgainstBaseURL: false)
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
        guard let req = try createBaseRequest(path: "tasks/\(id)", method: "PUT", body: request, accessToken: accessToken) else {
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

        let (data, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ApiError.networkError("Invalid response type")
        }
        guard httpResponse.statusCode == 204 || httpResponse.statusCode == 200 else {
            throw ApiError.networkError("Delete task failed with status: \(httpResponse.statusCode)")
        }
    }
    // func postSession(_ record: SessionRecord, accessToken: String) async throws
    // func fetchSessions(accessToken: String) async throws -> [SessionRecordDto]
}



// MARK: - Error Handling
enum ApiError: Error {
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