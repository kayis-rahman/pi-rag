//
//  TestDataFixtures.swift
//  TimeBeamTests
//
//  Created by TimeBeam Team
//  Comprehensive test data fixtures for consistent testing
//  Providing realistic test data across all test scenarios
//  Following Cline and Kilo code rules for test data management

import Foundation

// MARK: - Test Data Factory

/// Comprehensive test data factory for generating consistent test fixtures
struct TestDataFactory {

    // MARK: - User Data

    static func createTestUser(id: UUID = UUID(),
                              email: String = "test@example.com",
                              displayName: String = "Test User",
                              timezone: String = "UTC") -> [String: Any] {
        return [
            "id": id.uuidString,
            "email": email,
            "displayName": displayName,
            "timezone": timezone,
            "isAdmin": false,
            "createdAt": ISO8601DateFormatter().string(from: Date()),
            "updatedAt": ISO8601DateFormatter().string(from: Date())
        ]
    }

    static func createAuthenticatedUser() -> [String: Any] {
        return createTestUser(
            id: UUID(uuidString: "550e8400-e29b-41d4-a716-446655440000")!,
            email: "authenticated@test.com",
            displayName: "Authenticated User"
        )
    }

    // MARK: - Task Data

    static func createTestTask(id: UUID = UUID(),
                              userId: UUID = UUID(uuidString: "550e8400-e29b-41d4-a716-446655440000")!,
                              title: String = "Test Task",
                              description: String? = "Test task description",
                              status: TaskStatus = .todo,
                              createdAt: Date = Date(),
                              updatedAt: Date = Date()) -> [String: Any] {
        return [
            "id": id.uuidString,
            "userId": userId.uuidString,
            "title": title,
            "description": description as Any,
            "status": status.rawValue,
            "createdAt": ISO8601DateFormatter().string(from: createdAt),
            "updatedAt": ISO8601DateFormatter().string(from: updatedAt)
        ]
    }

    static func createTaskWithLongTitle() -> [String: Any] {
        return createTestTask(
            title: String(repeating: "A", count: 255),
            description: "Task with maximum allowed title length"
        )
    }

    static func createTaskWithLongDescription() -> [String: Any] {
        return createTestTask(
            title: "Task with Long Description",
            description: String(repeating: "This is a very long description. ", count: 50)
        )
    }

    static func createTaskWithUnicodeContent() -> [String: Any] {
        return createTestTask(
            title: "任务 🚀",
            description: "Description with émojis 📱💻 and spëcial chärs"
        )
    }

    static func createCompletedTask() -> [String: Any] {
        return createTestTask(
            title: "Completed Task",
            status: .completed,
            createdAt: Date().addingTimeInterval(-86400), // Yesterday
            updatedAt: Date().addingTimeInterval(-3600)   // 1 hour ago
        )
    }

    static func createInProgressTask() -> [String: Any] {
        return createTestTask(
            title: "In Progress Task",
            status: .inProgress,
            createdAt: Date().addingTimeInterval(-3600), // 1 hour ago
            updatedAt: Date()
        )
    }

    // MARK: - Session Data

    static func createTestSession(id: UUID = UUID(),
                                 userId: UUID = UUID(uuidString: "550e8400-e29b-41d4-a716-446655440000")!,
                                 taskId: UUID? = nil,
                                 startedAt: Date = Date(),
                                 durationSeconds: Int = 1500,
                                 kind: String = "work",
                                 completed: Bool = true) -> [String: Any] {
        return [
            "id": id.uuidString,
            "userId": userId.uuidString,
            "taskId": taskId?.uuidString as Any,
            "startedAt": ISO8601DateFormatter().string(from: startedAt),
            "durationSeconds": durationSeconds,
            "kind": kind,
            "wasCompleted": completed,
            "wasInterrupted": !completed,
            "interruptionReason": completed ? nil : "Test interruption" as Any,
            "createdAt": ISO8601DateFormatter().string(from: startedAt)
        ]
    }

    static func createWorkSession() -> [String: Any] {
        return createTestSession(
            startedAt: Date().addingTimeInterval(-1500), // 25 minutes ago
            durationSeconds: 1500, // 25 minutes
            kind: "work"
        )
    }

    static func createBreakSession() -> [String: Any] {
        return createTestSession(
            startedAt: Date().addingTimeInterval(-300), // 5 minutes ago
            durationSeconds: 300, // 5 minutes
            kind: "short_break"
        )
    }

    static func createInterruptedSession() -> [String: Any] {
        return createTestSession(
            startedAt: Date().addingTimeInterval(-1800), // 30 minutes ago
            durationSeconds: 900, // 15 minutes (interrupted)
            completed: false
        )
    }

    // MARK: - Analytics Data

    static func createTestAnalytics() -> [String: Any] {
        return [
            "totalWorkMinutes": 2400,
            "totalSessions": 45,
            "currentStreak": 7,
            "longestStreak": 12,
            "weeklyGoal": 1200,
            "completionRate": 85.5,
            "averageSessionLength": 25.0,
            "mostProductiveHour": 10,
            "dailyBreakdown": [
                ["day": "Mon", "minutes": 240],
                ["day": "Tue", "minutes": 300],
                ["day": "Wed", "minutes": 180],
                ["day": "Thu", "minutes": 360],
                ["day": "Fri", "minutes": 240],
                ["day": "Sat", "minutes": 120],
                ["day": "Sun", "minutes": 60]
            ],
            "hourlyBreakdown": [
                ["hour": 9, "sessions": 5, "minutes": 125],
                ["hour": 10, "sessions": 8, "minutes": 200],
                ["hour": 11, "sessions": 6, "minutes": 150],
                ["hour": 14, "sessions": 7, "minutes": 175],
                ["hour": 15, "sessions": 4, "minutes": 100],
                ["hour": 16, "sessions": 3, "minutes": 75]
            ]
        ]
    }

    static func createEmptyAnalytics() -> [String: Any] {
        return [
            "totalWorkMinutes": 0,
            "totalSessions": 0,
            "currentStreak": 0,
            "longestStreak": 0,
            "weeklyGoal": 1200,
            "completionRate": 0.0,
            "averageSessionLength": 0.0,
            "mostProductiveHour": nil,
            "dailyBreakdown": [],
            "hourlyBreakdown": []
        ]
    }

    // MARK: - Settings Data

    static func createTestSettings() -> [String: Any] {
        return [
            "workDurationMinutes": 25,
            "shortBreakMinutes": 5,
            "longBreakMinutes": 15,
            "sessionsBeforeLongBreak": 4,
            "autoStartBreaks": true,
            "autoStartWork": false,
            "dailyGoalMinutes": 120,
            "theme": "system",
            "soundEnabled": true,
            "notificationsEnabled": true
        ]
    }

    static func createCustomSettings() -> [String: Any] {
        return [
            "workDurationMinutes": 30,
            "shortBreakMinutes": 10,
            "longBreakMinutes": 20,
            "sessionsBeforeLongBreak": 3,
            "autoStartBreaks": false,
            "autoStartWork": true,
            "dailyGoalMinutes": 180,
            "theme": "dark",
            "soundEnabled": false,
            "notificationsEnabled": false
        ]
    }

    // MARK: - Bulk Data Generators

    static func createMultipleTasks(count: Int,
                                   userId: UUID = UUID(uuidString: "550e8400-e29b-41d4-a716-446655440000")!,
                                   baseDate: Date = Date()) -> [[String: Any]] {
        return (0..<count).map { index in
            let status: TaskStatus = index % 3 == 0 ? .completed : (index % 3 == 1 ? .inProgress : .todo)
            let createdAt = baseDate.addingTimeInterval(-Double(index) * 86400) // Days ago

            return createTestTask(
                title: "Task \(index + 1)",
                description: "Description for task \(index + 1)",
                status: status,
                createdAt: createdAt,
                updatedAt: createdAt.addingTimeInterval(3600) // 1 hour later
            )
        }
    }

    static func createMultipleSessions(count: Int,
                                      userId: UUID = UUID(uuidString: "550e8400-e29b-41d4-a716-446655440000")!,
                                      baseDate: Date = Date()) -> [[String: Any]] {
        return (0..<count).map { index in
            let sessionType = index % 3
            let duration: Int
            let kind: String

            switch sessionType {
            case 0:
                duration = 1500 // 25 minutes work
                kind = "work"
            case 1:
                duration = 300  // 5 minutes short break
                kind = "short_break"
            default:
                duration = 900  // 15 minutes long break
                kind = "long_break"
            }

            let startedAt = baseDate.addingTimeInterval(-Double(index) * 1800) // 30 minutes apart

            return createTestSession(
                userId: userId,
                startedAt: startedAt,
                durationSeconds: duration,
                kind: kind
            )
        }
    }

    static func createTaskWithSessions(taskId: UUID = UUID(),
                                      userId: UUID = UUID(uuidString: "550e8400-e29b-41d4-a716-446655440000")!,
                                      sessionCount: Int = 3) -> ([String: Any], [[String: Any]]) {
        let task = createTestTask(
            id: taskId,
            userId: userId,
            title: "Task with Sessions",
            status: .inProgress
        )

        let sessions = (0..<sessionCount).map { index in
            createTestSession(
                userId: userId,
                taskId: taskId,
                startedAt: Date().addingTimeInterval(-Double(index + 1) * 3600), // Hours ago
                durationSeconds: 1500 + (index * 300), // Increasing duration
                kind: "work"
            )
        }

        return (task, sessions)
    }

    // MARK: - Edge Cases and Invalid Data

    static func createInvalidTaskData() -> [[String: Any]] {
        return [
            // Empty title
            [
                "id": UUID().uuidString,
                "userId": UUID().uuidString,
                "title": "",
                "status": "todo",
                "createdAt": ISO8601DateFormatter().string(from: Date()),
                "updatedAt": ISO8601DateFormatter().string(from: Date())
            ],
            // Title too long
            [
                "id": UUID().uuidString,
                "userId": UUID().uuidString,
                "title": String(repeating: "A", count: 256),
                "status": "todo",
                "createdAt": ISO8601DateFormatter().string(from: Date()),
                "updatedAt": ISO8601DateFormatter().string(from: Date())
            ],
            // Invalid status
            [
                "id": UUID().uuidString,
                "userId": UUID().uuidString,
                "title": "Valid Title",
                "status": "invalid_status",
                "createdAt": ISO8601DateFormatter().string(from: Date()),
                "updatedAt": ISO8601DateFormatter().string(from: Date())
            ],
            // Future created date
            [
                "id": UUID().uuidString,
                "userId": UUID().uuidString,
                "title": "Future Task",
                "status": "todo",
                "createdAt": ISO8601DateFormatter().string(from: Date().addingTimeInterval(86400)),
                "updatedAt": ISO8601DateFormatter().string(from: Date())
            ]
        ]
    }

    static func createInvalidSessionData() -> [[String: Any]] {
        return [
            // Negative duration
            [
                "id": UUID().uuidString,
                "userId": UUID().uuidString,
                "startedAt": ISO8601DateFormatter().string(from: Date()),
                "durationSeconds": -100,
                "kind": "work",
                "wasCompleted": true,
                "createdAt": ISO8601DateFormatter().string(from: Date())
            ],
            // Future start time
            [
                "id": UUID().uuidString,
                "userId": UUID().uuidString,
                "startedAt": ISO8601DateFormatter().string(from: Date().addingTimeInterval(3600)),
                "durationSeconds": 1500,
                "kind": "work",
                "wasCompleted": true,
                "createdAt": ISO8601DateFormatter().string(from: Date())
            ],
            // Invalid session kind
            [
                "id": UUID().uuidString,
                "userId": UUID().uuidString,
                "startedAt": ISO8601DateFormatter().string(from: Date()),
                "durationSeconds": 1500,
                "kind": "invalid_kind",
                "wasCompleted": true,
                "createdAt": ISO8601DateFormatter().string(from: Date())
            ]
        ]
    }

    // MARK: - Performance Test Data

    static func createLargeTaskDataset(count: Int = 1000) -> [[String: Any]] {
        return createMultipleTasks(count: count)
    }

    static func createLargeSessionDataset(count: Int = 10000) -> [[String: Any]] {
        return createMultipleSessions(count: count)
    }

    // MARK: - Localization Test Data

    static func createLocalizedTaskData() -> [String: [String: Any]] {
        return [
            "en": createTestTask(title: "Hello World", description: "Simple greeting task"),
            "es": createTestTask(title: "Hola Mundo", description: "Tarea de saludo simple"),
            "fr": createTestTask(title: "Bonjour le Monde", description: "Tâche de salutation simple"),
            "de": createTestTask(title: "Hallo Welt", description: "Einfache Begrüßungsaufgabe"),
            "ja": createTestTask(title: "こんにちは世界", description: "シンプルな挨拶タスク")
        ]
    }

    // MARK: - JSON Response Mocks

    static func createAPIResponse<T: Encodable>(_ data: T) -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try! encoder.encode(data)
    }

    static func createAPIErrorResponse(code: Int = 400, message: String = "Bad Request") -> Data {
        let errorData: [String: Any] = [
            "error": true,
            "code": code,
            "message": message,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        return try! JSONSerialization.data(withJSONObject: errorData, options: [])
    }

    // MARK: - Test Scenario Builders

    static func createCompleteUserScenario() -> [String: Any] {
        let userId = UUID(uuidString: "550e8400-e29b-41d4-a716-446655440000")!
        let user = createAuthenticatedUser()

        let tasks = createMultipleTasks(count: 5, userId: userId)
        let sessions = createMultipleSessions(count: 20, userId: userId)
        let analytics = createTestAnalytics()
        let settings = createTestSettings()

        return [
            "user": user,
            "tasks": tasks,
            "sessions": sessions,
            "analytics": analytics,
            "settings": settings
        ]
    }

    static func createEmptyUserScenario() -> [String: Any] {
        let user = createAuthenticatedUser()

        return [
            "user": user,
            "tasks": [],
            "sessions": [],
            "analytics": createEmptyAnalytics(),
            "settings": createTestSettings()
        ]
    }

    static func createErrorScenario() -> [String: Any] {
        return [
            "networkError": createAPIErrorResponse(code: 500, message: "Internal Server Error"),
            "validationError": createAPIErrorResponse(code: 400, message: "Validation failed"),
            "unauthorizedError": createAPIErrorResponse(code: 401, message: "Unauthorized"),
            "notFoundError": createAPIErrorResponse(code: 404, message: "Resource not found")
        ]
    }
}

// MARK: - Test Data Validators

/// Validators for test data integrity
struct TestDataValidator {

    static func validateTaskData(_ task: [String: Any]) -> Bool {
        guard let id = task["id"] as? String,
              let userId = task["userId"] as? String,
              let title = task["title"] as? String,
              let status = task["status"] as? String,
              let createdAt = task["createdAt"] as? String,
              let updatedAt = task["updatedAt"] as? String else {
            return false
        }

        // Validate UUIDs
        guard UUID(uuidString: id) != nil,
              UUID(uuidString: userId) != nil else {
            return false
        }

        // Validate title
        guard !title.isEmpty && title.count <= 255 else {
            return false
        }

        // Validate status
        let validStatuses = ["todo", "in_progress", "completed"]
        guard validStatuses.contains(status) else {
            return false
        }

        // Validate dates
        let dateFormatter = ISO8601DateFormatter()
        guard dateFormatter.date(from: createdAt) != nil,
              dateFormatter.date(from: updatedAt) != nil else {
            return false
        }

        return true
    }

    static func validateSessionData(_ session: [String: Any]) -> Bool {
        guard let id = session["id"] as? String,
              let userId = session["userId"] as? String,
              let startedAt = session["startedAt"] as? String,
              let durationSeconds = session["durationSeconds"] as? Int,
              let kind = session["kind"] as? String,
              let wasCompleted = session["wasCompleted"] as? Bool else {
            return false
        }

        // Validate UUIDs
        guard UUID(uuidString: id) != nil,
              UUID(uuidString: userId) != nil else {
            return false
        }

        // Validate duration
        guard durationSeconds > 0 && durationSeconds <= 24 * 60 * 60 else { // Max 24 hours
            return false
        }

        // Validate session kind
        let validKinds = ["work", "short_break", "long_break"]
        guard validKinds.contains(kind) else {
            return false
        }

        // Validate date
        let dateFormatter = ISO8601DateFormatter()
        guard dateFormatter.date(from: startedAt) != nil else {
            return false
        }

        return true
    }

    static func validateAnalyticsData(_ analytics: [String: Any]) -> Bool {
        guard let totalWorkMinutes = analytics["totalWorkMinutes"] as? Int,
              let totalSessions = analytics["totalSessions"] as? Int,
              let currentStreak = analytics["currentStreak"] as? Int,
              let longestStreak = analytics["longestStreak"] as? Int,
              let completionRate = analytics["completionRate"] as? Double else {
            return false
        }

        // Validate ranges
        guard totalWorkMinutes >= 0,
              totalSessions >= 0,
              currentStreak >= 0,
              longestStreak >= 0,
              completionRate >= 0.0 && completionRate <= 100.0 else {
            return false
        }

        return true
    }
}

// MARK: - Test Data Persistence

/// Test data persistence utilities
struct TestDataPersistence {

    private static let testDataDirectory = "TestData"

    static func saveTestData<T: Encodable>(_ data: T, filename: String) {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        let testDataDir = tempDir.appendingPathComponent(testDataDirectory)

        try? fileManager.createDirectory(at: testDataDir, withIntermediateDirectories: true)

        let fileURL = testDataDir.appendingPathComponent(filename)

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601

        let data = try! encoder.encode(data)
        try! data.write(to: fileURL)
    }

    static func loadTestData<T: Decodable>(filename: String) -> T? {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(testDataDirectory).appendingPathComponent(filename)

        guard let data = try? Data(contentsOf: fileURL) else { return nil }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return try? decoder.decode(T.self, from: data)
    }

    static func clearTestData() {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        let testDataDir = tempDir.appendingPathComponent(testDataDirectory)

        try? fileManager.removeItem(at: testDataDir)
    }
}

// MARK: - Test Data Extensions

extension Array where Element == [String: Any] {

    func validatedTasks() -> [[String: Any]] {
        return self.filter { TestDataValidator.validateTaskData($0) }
    }

    func validatedSessions() -> [[String: Any]] {
        return self.filter { TestDataValidator.validateSessionData($0) }
    }

    func saveAsJSON(filename: String) {
        TestDataPersistence.saveTestData(self, filename: filename)
    }
}

extension Dictionary where Key == String, Value == Any {

    func validatedAnalytics() -> Bool {
        return TestDataValidator.validateAnalyticsData(self)
    }

    func saveAsJSON(filename: String) {
        TestDataPersistence.saveTestData(self, filename: filename)
    }
}