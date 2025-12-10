import Foundation
import os

struct ApiClient {
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

    private let config: Configuration
    private let urlSession: URLSession

    init(configuration: Configuration, urlSession: URLSession = .shared) {
        self.config = configuration
        self.urlSession = urlSession
    }

    static let shared: ApiClient = {
        guard let config = Configuration.fromInfoPlist() else {
            fatalError("API configuration not found in Info.plist")
        }
        return ApiClient(configuration: config)
    }()

    // MARK: - DTOs

    struct RegisterRequest: Codable {
        let email: String
        let displayName: String?
    }

    struct LoginRequest: Codable {
        let email: String
    }

    struct LoginResponse: Codable {
        let accessToken: String
    }

    struct SessionPayload: Codable {
        let id: UUID
        let startedAt: Date
        let duration: TimeInterval
        let kind: String
    }

    struct SessionRecordDto: Codable, Identifiable {
        let id: UUID
        let userId: UUID
        let startedAt: Date
        let durationSeconds: Int
        let kind: String
    }

    struct TimerStateDto: Codable {
        let startTimestamp: Double?
        let pauseTimestamp: Double?
        let totalDuration: Int
        let remainingSeconds: Int
        let phase: String
        let isRunning: Bool
        let workDuration: Int
        let breakDuration: Int
        let longBreakDuration: Int
        let autoStartNextSession: Bool
        let shortBreaksCompleted: Int
        let lastModifiedTimestamp: Double
        let deviceId: String
    }

    struct TimerActionDto: Codable {
        let action: String
        let timestamp: Date
        let deviceId: String

        // Include the complete timer state with the action
        let phase: String
        let remainingSeconds: Int
        let isRunning: Bool
        let workDuration: Int
        let breakDuration: Int
        let longBreakDuration: Int
        let autoStartNextSession: Bool
        let shortBreaksCompleted: Int
    }

    struct DeviceRegistrationDto: Codable {
        let deviceId: String
        let deviceName: String
        let deviceType: String
        let platformVersion: String?
        let appVersion: String?
        let fcmToken: String?
    }

    struct DeviceStats: Codable {
        let totalDevices: Int
        let activeDevices: Int
        let iosDevices: Int
        let macosDevices: Int
        let watchosDevices: Int
    }

    // MARK: - Task DTOs

    struct TaskCreateRequest: Codable {
        let title: String
        let description: String?
    }

    struct TaskUpdateRequest: Codable {
        let title: String?
        let description: String?
        let status: String?
    }

    struct TaskDto: Codable, Identifiable {
        let id: UUID
        let userId: UUID
        let title: String
        let description: String?
        let status: String
        let createdAt: Date
        let updatedAt: Date
    }

    enum SessionKind: String {
        case work = "work"
        case shortBreak = "short_break"
        case longBreak = "long_break"
    }

    // MARK: - Endpoints

    func register(email: String, displayName: String?) async throws {
        let body = RegisterRequest(email: email, displayName: displayName)
        var req = try makeRequest(path: "/api/auth/register", method: "POST", jsonBody: body)
        let _: EmptyResponse = try await perform(&req)
    }

    func login(email: String) async throws -> LoginResponse {
        let body = LoginRequest(email: email)
        var req = try makeRequest(path: "/api/auth/login", method: "POST", jsonBody: body)
        let response: LoginResponse = try await perform(&req)
        return response
    }

    func postSession(_ record: SessionRecord, accessToken: String) async throws {
        LoggerStore.session.info("Creating session via POST for local record id: \(record.id.uuidString, privacy: .public)")
        var req = try makeRequest(
            path: "/api/sessions",
            method: "POST",
            jsonBody: SessionPayload(
                id: record.id,
                startedAt: record.startedAt,
                duration: record.duration,
                kind: record.kind.rawValue
            )
        )
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let _: EmptyResponse = try await perform(&req)
        LoggerStore.session.debug("POST /api/sessions completed for local record id: \(record.id.uuidString, privacy: .public)")
    }

    func fetchSessions(accessToken: String) async throws -> [SessionPayload] {
        var req = URLRequest(url: config.baseURL.appendingPathComponent("/api/sessions"))
        req.httpMethod = "GET"
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let response: [SessionPayload] = try await perform(req)
        return response
    }

    func startSession(kind: SessionKind, taskId: UUID? = nil, accessToken: String) async throws -> SessionRecordDto {
        LoggerStore.session.info("Starting session of kind: \(kind.rawValue, privacy: .public), taskId: \(String(describing: taskId))")
        var components = URLComponents(url: config.baseURL.appendingPathComponent("/api/sessions/start"), resolvingAgainstBaseURL: false)
        var queryItems = [URLQueryItem(name: "kind", value: kind.rawValue)]
        if let taskId = taskId {
            queryItems.append(URLQueryItem(name: "taskId", value: taskId.uuidString))
        }
        components?.queryItems = queryItems
        guard let url = components?.url else { throw ApiError.invalidResponse }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let session: SessionRecordDto = try await perform(&req)
        LoggerStore.session.debug("Session started successfully with id: \(session.id.uuidString, privacy: .public)")
        return session
    }

    func stopSession(id: UUID, accessToken: String) async throws -> SessionRecordDto {
        let url = config.baseURL.appendingPathComponent("/api/sessions/\(id.uuidString)/stop")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let response: SessionRecordDto = try await perform(&req)
        return response
    }

    // MARK: - Timer Sync Endpoints

    func pushTimerState(_ state: TimerStateDto, accessToken: String) async throws {
        AppLogger.logAPIEvent("timer_state_push_requested", url: "/api/sessions/timer/state")
        var req = try makeRequest(path: "/api/sessions/timer/state", method: "POST", jsonBody: state)
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let _: EmptyResponse = try await perform(&req)
        AppLogger.logAPIEvent("timer_state_push_success")
    }

    func pullTimerState(accessToken: String) async throws -> TimerStateDto? {
        AppLogger.logAPIEvent("timer_state_pull_requested", url: "/api/sessions/timer/state")
        var req = URLRequest(url: config.baseURL.appendingPathComponent("/api/sessions/timer/state"))
        req.httpMethod = "GET"
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await urlSession.data(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw ApiError.invalidResponse
        }
        guard 200..<300 ~= http.statusCode || http.statusCode == 204 else {
            throw ApiError.httpStatus(code: http.statusCode, body: String(data: data, encoding: .utf8))
        }

        // Handle 204 No Content - no timer state available
        if http.statusCode == 204 {
            AppLogger.debug("No timer state available from backend (204)", category: .sync)
            return nil
        }

        // Log response details for debugging
        AppLogger.debug("Timer state pull response: status=\(http.statusCode), dataSize=\(data.count)", category: .sync)
        if let responseString = String(data: data, encoding: .utf8) {
            AppLogger.debug("Timer state pull response body: \(responseString)", category: .sync) // Log full response
        }

        // Handle empty data with other status codes as error
        if data.isEmpty {
            AppLogger.error("Empty response from timer state pull (status: \(http.statusCode))", category: .sync)
            throw ApiError.invalidResponse
        }

        // Debug: Check if JSON is valid before decoding
        if let jsonString = String(data: data, encoding: .utf8) {
            print("DEBUG: About to decode JSON: \(jsonString)")
            // Check if the timestamp looks correct
            if jsonString.contains("\"lastModifiedTimestamp\":") {
                print("DEBUG: Found timestamp in JSON")
            }
        }

        // Decode the timer state
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        print("DEBUG: Starting JSON decoding...")
        let state = try decoder.decode(TimerStateDto.self, from: data)
        print("DEBUG: JSON decoding successful, timestamp: \(state.lastModifiedTimestamp)")
        AppLogger.logAPIEvent("timer_state_pull_success", url: "/api/sessions/timer/state")
        return state
    }

    func pushTimerAction(_ action: TimerActionDto, accessToken: String) async throws {
        AppLogger.logAPIEvent("timer_action_push_requested", url: "/api/sessions/timer/action")
        var req = try makeRequest(path: "/api/sessions/timer/action", method: "POST", jsonBody: action)
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let _: EmptyResponse = try await perform(&req)
        AppLogger.logAPIEvent("timer_action_push_success")
    }

    // MARK: - Device Management Endpoints

    func registerDevice(_ device: DeviceRegistrationDto, accessToken: String) async throws {
        AppLogger.logAPIEvent("device_registration_requested", url: "/api/devices/register")
        var req = try makeRequest(path: "/api/devices/register", method: "POST", jsonBody: device)
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let _: EmptyResponse = try await perform(&req)
        AppLogger.logAPIEvent("device_registration_success")
    }

    func getDeviceStats(accessToken: String) async throws -> DeviceStats {
        AppLogger.logAPIEvent("device_stats_requested", url: "/api/devices/stats")
        var req = URLRequest(url: config.baseURL.appendingPathComponent("/api/devices/stats"))
        req.httpMethod = "GET"
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let stats: DeviceStats = try await perform(req)
        AppLogger.logAPIEvent("device_stats_success")
        return stats
    }

    func updateApnsToken(deviceId: String, apnsToken: String, accessToken: String) async throws {
        AppLogger.logAPIEvent("apns_token_update_requested", url: "/api/sessions/devices/apns-token")
        var components = URLComponents(url: config.baseURL.appendingPathComponent("/api/sessions/devices/apns-token"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "deviceId", value: deviceId),
            URLQueryItem(name: "apnsToken", value: apnsToken)
        ]
        guard let url = components?.url else { throw ApiError.invalidResponse }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let _: EmptyResponse = try await perform(&req)
        AppLogger.logAPIEvent("apns_token_update_success")
    }

    struct ApnNotificationPayload: Codable {
        let type: String
        let action: TimerSyncAction
    }

    struct TimerSyncAction: Codable {
        let action: String
        let deviceId: String
        let timestamp: String
    }

    func sendApnNotification(payload: ApnNotificationPayload, accessToken: String) async throws {
        AppLogger.logAPIEvent("apn_notification_send_requested", url: "/api/notifications/send")
        var req = try makeRequest(path: "/api/notifications/send", method: "POST", jsonBody: payload)
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let _: EmptyResponse = try await perform(&req)
        AppLogger.logAPIEvent("apn_notification_send_success")
    }

    // MARK: - Task Management Endpoints

    func createTask(_ request: TaskCreateRequest, accessToken: String) async throws -> TaskDto {
        AppLogger.logAPIEvent("task_create_requested", url: "/api/tasks")
        var req = try makeRequest(path: "/api/tasks", method: "POST", jsonBody: request)
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let task: TaskDto = try await perform(&req)
        AppLogger.logAPIEvent("task_create_success")
        return task
    }

    func fetchTasks(accessToken: String) async throws -> [TaskDto] {
        AppLogger.logAPIEvent("tasks_fetch_requested", url: "/api/tasks")
        var req = URLRequest(url: config.baseURL.appendingPathComponent("/api/tasks"))
        req.httpMethod = "GET"
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let tasks: [TaskDto] = try await perform(req)
        AppLogger.logAPIEvent("tasks_fetch_success")
        return tasks
    }

    func fetchActiveTasks(accessToken: String) async throws -> [TaskDto] {
        AppLogger.logAPIEvent("active_tasks_fetch_requested", url: "/api/tasks/active")
        var req = URLRequest(url: config.baseURL.appendingPathComponent("/api/tasks/active"))
        req.httpMethod = "GET"
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let tasks: [TaskDto] = try await perform(req)
        AppLogger.logAPIEvent("active_tasks_fetch_success")
        return tasks
    }

    func fetchTask(id: UUID, accessToken: String) async throws -> TaskDto {
        AppLogger.logAPIEvent("task_fetch_requested", url: "/api/tasks/\(id.uuidString)")
        var req = URLRequest(url: config.baseURL.appendingPathComponent("/api/tasks/\(id.uuidString)"))
        req.httpMethod = "GET"
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let task: TaskDto = try await perform(req)
        AppLogger.logAPIEvent("task_fetch_success")
        return task
    }

    func updateTask(id: UUID, _ request: TaskUpdateRequest, accessToken: String) async throws -> TaskDto {
        AppLogger.logAPIEvent("task_update_requested", url: "/api/tasks/\(id.uuidString)")
        var req = try makeRequest(path: "/api/tasks/\(id.uuidString)", method: "PUT", jsonBody: request)
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let task: TaskDto = try await perform(&req)
        AppLogger.logAPIEvent("task_update_success")
        return task
    }

    func deleteTask(id: UUID, accessToken: String) async throws {
        AppLogger.logAPIEvent("task_delete_requested", url: "/api/tasks/\(id.uuidString)")
        var req = URLRequest(url: config.baseURL.appendingPathComponent("/api/tasks/\(id.uuidString)"))
        req.httpMethod = "DELETE"
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let _: EmptyResponse = try await perform(&req)
        AppLogger.logAPIEvent("task_delete_success")
    }

    // MARK: - Core helpers

    func makeRequest<T: Encodable>(path: String, method: String, jsonBody: T) throws -> URLRequest {
        let url = config.baseURL.appendingPathComponent(path)
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(jsonBody)
        return req
    }

    func perform<T: Decodable>(_ request: inout URLRequest) async throws -> T {
        let (data, response) = try await urlSession.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw ApiError.invalidResponse
        }
        guard 200..<300 ~= http.statusCode else {
            throw ApiError.httpStatus(code: http.statusCode, body: String(data: data, encoding: .utf8))
        }
        if T.self == EmptyResponse.self {
            return EmptyResponse() as! T
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: data)
    }

    func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        var mutableRequest = request
        return try await perform(&mutableRequest)
    }

    enum ApiError: LocalizedError {
        case invalidResponse
        case httpStatus(code: Int, body: String?)
        case missingConfiguration

        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "Invalid response from server"
            case .httpStatus(let code, let body):
                if let body = body, !body.isEmpty {
                    return body
                } else {
                    return "Server error (HTTP \(code))"
                }
            case .missingConfiguration:
                return "API configuration is missing"
            }
        }
    }

    struct EmptyResponse: Decodable {}
}
