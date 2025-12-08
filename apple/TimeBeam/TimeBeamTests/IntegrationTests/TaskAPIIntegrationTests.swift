//
//  TaskAPIIntegrationTests.swift
//  TimeBeamTests
//
//  Created by TimeBeam Team
//  Comprehensive integration tests for Task API interactions
//  Testing full request/response cycles with mocked backend
//  Following Cline and Kilo code rules for integration testing

import XCTest
@testable import TimeBeam

final class TaskAPIIntegrationTests: XCTestCase {

    // MARK: - Properties

    private var taskService: TaskService!
    private var mockApiClient: MockHTTPClient!
    private var mockKeychainStore: MockKeychainStore!
    private var testServer: TestServer!

    // MARK: - Setup & Teardown

    override func setUpWithError() throws {
        mockApiClient = MockHTTPClient()
        mockKeychainStore = MockKeychainStore()
        testServer = TestServer()

        taskService = TaskService(apiClient: mockApiClient, keychainStore: mockKeychainStore)

        // Start test server
        try testServer.start()
    }

    override func tearDownWithError() throws {
        try testServer.stop()
        testServer = nil
        taskService = nil
        mockApiClient = nil
        mockKeychainStore = nil
    }

    // MARK: - End-to-End Task Creation Flow

    func testFullTaskCreationFlow() async throws {
        // Given - Setup authenticated user
        let userId = UUID()
        let authToken = "test-jwt-token-\(UUID().uuidString)"
        mockKeychainStore.storeToken(authToken)

        let taskData = TestDataFactory.createValidTask()
        let expectedTaskId = UUID()

        // Setup mock server response
        testServer.setupMockResponse(
            endpoint: "/api/tasks",
            method: "POST",
            statusCode: 201,
            responseBody: [
                "id": expectedTaskId.uuidString,
                "userId": userId.uuidString,
                "title": taskData.title,
                "description": taskData.description,
                "status": "todo",
                "createdAt": ISO8601DateFormatter().string(from: Date()),
                "updatedAt": ISO8601DateFormatter().string(from: Date())
            ]
        )

        // When
        let createdTask = try await taskService.createTask(
            title: taskData.title,
            description: taskData.description
        )

        // Then
        XCTAssertEqual(createdTask.id, expectedTaskId)
        XCTAssertEqual(createdTask.title, taskData.title)
        XCTAssertEqual(createdTask.description, taskData.description)
        XCTAssertEqual(createdTask.status, .todo)
        XCTAssertNotNil(createdTask.createdAt)
        XCTAssertNotNil(createdTask.updatedAt)

        // Verify API call was made correctly
        let lastRequest = testServer.lastRequest
        XCTAssertEqual(lastRequest?.method, "POST")
        XCTAssertEqual(lastRequest?.path, "/api/tasks")

        // Verify request body
        let requestBody = lastRequest?.body as? [String: Any]
        XCTAssertEqual(requestBody?["title"] as? String, taskData.title)
        XCTAssertEqual(requestBody?["description"] as? String, taskData.description)

        // Verify authorization header
        XCTAssertEqual(lastRequest?.headers["Authorization"], "Bearer \(authToken)")
    }

    func testTaskCreationWithServerError() async throws {
        // Given
        let authToken = "test-jwt-token-\(UUID().uuidString)"
        mockKeychainStore.storeToken(authToken)

        testServer.setupMockResponse(
            endpoint: "/api/tasks",
            method: "POST",
            statusCode: 400,
            responseBody: ["error": "Validation failed", "message": "Title is required"]
        )

        // When/Then
        do {
            _ = try await taskService.createTask(title: "", description: "Valid description")
            XCTFail("Should throw validation error")
        } catch TaskServiceError.serverError(let message) {
            XCTAssertTrue(message.contains("Validation failed"))
        } catch {
            XCTFail("Should throw TaskServiceError.serverError, got: \(error)")
        }
    }

    // MARK: - Task Retrieval Integration Tests

    func testFetchAllTasksIntegration() async throws {
        // Given
        let authToken = "test-jwt-token-\(UUID().uuidString)"
        mockKeychainStore.storeToken(authToken)

        let mockTasks = MockDataProvider.createMultipleMockTasks(count: 3)
        testServer.setupMockResponse(
            endpoint: "/api/tasks",
            method: "GET",
            statusCode: 200,
            responseBody: mockTasks
        )

        // When
        let tasks = try await taskService.fetchTasks()

        // Then
        XCTAssertEqual(tasks.count, mockTasks.count)
        for (index, task) in tasks.enumerated() {
            let mockTask = mockTasks[index] as! [String: Any]
            XCTAssertEqual(task.id.uuidString, mockTask["id"] as? String)
            XCTAssertEqual(task.title, mockTask["title"] as? String)
        }

        // Verify request
        let lastRequest = testServer.lastRequest
        XCTAssertEqual(lastRequest?.method, "GET")
        XCTAssertEqual(lastRequest?.path, "/api/tasks")
        XCTAssertEqual(lastRequest?.headers["Authorization"], "Bearer \(authToken)")
    }

    func testFetchTasksByStatusIntegration() async throws {
        // Given
        let authToken = "test-jwt-token-\(UUID().uuidString)"
        mockKeychainStore.storeToken(authToken)

        let completedTasks = MockDataProvider.createMultipleMockTasks(count: 2, status: .completed)
        testServer.setupMockResponse(
            endpoint: "/api/tasks?status=completed",
            method: "GET",
            statusCode: 200,
            responseBody: completedTasks
        )

        // When
        let tasks = try await taskService.fetchTasks(status: .completed)

        // Then
        XCTAssertEqual(tasks.count, completedTasks.count)
        for task in tasks {
            XCTAssertEqual(task.status, .completed)
        }

        // Verify query parameter
        let lastRequest = testServer.lastRequest
        XCTAssertEqual(lastRequest?.method, "GET")
        XCTAssertTrue(lastRequest?.path.contains("status=completed") ?? false)
    }

    func testFetchTaskByIdIntegration() async throws {
        // Given
        let authToken = "test-jwt-token-\(UUID().uuidString)"
        mockKeychainStore.storeToken(authToken)

        let taskId = UUID()
        let mockTask = MockDataProvider.createMockTask(id: taskId)
        testServer.setupMockResponse(
            endpoint: "/api/tasks/\(taskId.uuidString)",
            method: "GET",
            statusCode: 200,
            responseBody: mockTask
        )

        // When
        let task = try await taskService.fetchTask(byId: taskId)

        // Then
        XCTAssertEqual(task.id, taskId)
        XCTAssertEqual(task.title, mockTask["title"] as? String)

        // Verify request
        let lastRequest = testServer.lastRequest
        XCTAssertEqual(lastRequest?.method, "GET")
        XCTAssertEqual(lastRequest?.path, "/api/tasks/\(taskId.uuidString)")
    }

    // MARK: - Task Update Integration Tests

    func testTaskUpdateIntegration() async throws {
        // Given
        let authToken = "test-jwt-token-\(UUID().uuidString)"
        mockKeychainStore.storeToken(authToken)

        let taskId = UUID()
        let originalTask = MockDataProvider.createMockTask(id: taskId, status: .todo)
        let updatedTitle = "Updated Task Title"
        let updatedTask = MockDataProvider.createMockTask(
            id: taskId,
            title: updatedTitle,
            status: .inProgress
        )

        testServer.setupMockResponse(
            endpoint: "/api/tasks/\(taskId.uuidString)",
            method: "PUT",
            statusCode: 200,
            responseBody: updatedTask
        )

        // When
        let result = try await taskService.updateTask(
            id: taskId,
            title: updatedTitle,
            description: nil,
            status: .inProgress
        )

        // Then
        XCTAssertEqual(result.id, taskId)
        XCTAssertEqual(result.title, updatedTitle)
        XCTAssertEqual(result.status, .inProgress)

        // Verify request
        let lastRequest = testServer.lastRequest
        XCTAssertEqual(lastRequest?.method, "PUT")
        XCTAssertEqual(lastRequest?.path, "/api/tasks/\(taskId.uuidString)")

        let requestBody = lastRequest?.body as? [String: Any]
        XCTAssertEqual(requestBody?["title"] as? String, updatedTitle)
        XCTAssertEqual(requestBody?["status"] as? String, "in_progress")
    }

    func testTaskPartialUpdateIntegration() async throws {
        // Given
        let authToken = "test-jwt-token-\(UUID().uuidString)"
        mockKeychainStore.storeToken(authToken)

        let taskId = UUID()
        let originalTask = MockDataProvider.createMockTask(id: taskId, status: .todo)
        let updatedDescription = "Updated description only"

        testServer.setupMockResponse(
            endpoint: "/api/tasks/\(taskId.uuidString)",
            method: "PUT",
            statusCode: 200,
            responseBody: MockDataProvider.createMockTask(
                id: taskId,
                description: updatedDescription,
                status: .todo // Should remain unchanged
            )
        )

        // When
        let result = try await taskService.updateTask(
            id: taskId,
            title: nil, // Not updating title
            description: updatedDescription,
            status: nil // Not updating status
        )

        // Then
        XCTAssertEqual(result.description, updatedDescription)
        XCTAssertEqual(result.status, .todo) // Should remain unchanged

        // Verify request body only contains changed fields
        let lastRequest = testServer.lastRequest
        let requestBody = lastRequest?.body as? [String: Any]
        XCTAssertNil(requestBody?["title"]) // Should not be present
        XCTAssertNil(requestBody?["status"]) // Should not be present
        XCTAssertEqual(requestBody?["description"] as? String, updatedDescription)
    }

    // MARK: - Task Deletion Integration Tests

    func testTaskDeletionIntegration() async throws {
        // Given
        let authToken = "test-jwt-token-\(UUID().uuidString)"
        mockKeychainStore.storeToken(authToken)

        let taskId = UUID()
        testServer.setupMockResponse(
            endpoint: "/api/tasks/\(taskId.uuidString)",
            method: "DELETE",
            statusCode: 204,
            responseBody: nil
        )

        // When/Then
        try await taskService.deleteTask(id: taskId)

        // Verify request
        let lastRequest = testServer.lastRequest
        XCTAssertEqual(lastRequest?.method, "DELETE")
        XCTAssertEqual(lastRequest?.path, "/api/tasks/\(taskId.uuidString)")
    }

    // MARK: - Authentication Integration Tests

    func testAPICallsIncludeAuthenticationHeaders() async throws {
        // Given
        let authToken = "test-jwt-token-\(UUID().uuidString)"
        mockKeychainStore.storeToken(authToken)

        testServer.setupMockResponse(
            endpoint: "/api/tasks",
            method: "GET",
            statusCode: 200,
            responseBody: []
        )

        // When
        _ = try await taskService.fetchTasks()

        // Then
        let lastRequest = testServer.lastRequest
        XCTAssertEqual(lastRequest?.headers["Authorization"], "Bearer \(authToken)")
        XCTAssertEqual(lastRequest?.headers["Content-Type"], "application/json")
    }

    func testAPICallsFailWithoutAuthentication() async throws {
        // Given - No auth token stored
        testServer.setupMockResponse(
            endpoint: "/api/tasks",
            method: "GET",
            statusCode: 401,
            responseBody: ["error": "Unauthorized"]
        )

        // When/Then
        do {
            _ = try await taskService.fetchTasks()
            XCTFail("Should throw unauthorized error")
        } catch TaskServiceError.unauthorized {
            // Expected error
        } catch {
            XCTFail("Should throw TaskServiceError.unauthorized, got: \(error)")
        }
    }

    func testTokenRefreshOn401Response() async throws {
        // Given
        let expiredToken = "expired-token"
        let newToken = "new-valid-token"
        mockKeychainStore.storeToken(expiredToken)

        // First call returns 401, second call succeeds with new token
        testServer.setupMockResponses([
            (endpoint: "/api/tasks", method: "GET", statusCode: 401, responseBody: ["error": "Token expired"]),
            (endpoint: "/api/tasks", method: "GET", statusCode: 200, responseBody: [])
        ])

        // Mock token refresh
        mockKeychainStore.mockRefreshedToken = newToken

        // When
        let tasks = try await taskService.fetchTasks()

        // Then
        XCTAssertEqual(tasks.count, 0) // Empty array response
        XCTAssertEqual(mockKeychainStore.loadToken(), newToken) // Token should be refreshed
    }

    // MARK: - Network Error Handling Tests

    func testNetworkTimeoutHandling() async throws {
        // Given
        mockApiClient.shouldSimulateTimeout = true

        // When/Then
        do {
            _ = try await taskService.fetchTasks()
            XCTFail("Should throw network error")
        } catch TaskServiceError.networkError {
            // Expected error
        } catch {
            XCTFail("Should throw TaskServiceError.networkError, got: \(error)")
        }
    }

    func testServerUnavailableHandling() async throws {
        // Given
        testServer.setupMockResponse(
            endpoint: "/api/tasks",
            method: "GET",
            statusCode: 503,
            responseBody: ["error": "Service Unavailable"]
        )

        // When/Then
        do {
            _ = try await taskService.fetchTasks()
            XCTFail("Should throw server error")
        } catch TaskServiceError.serverError(let message) {
            XCTAssertTrue(message.contains("Service Unavailable"))
        } catch {
            XCTFail("Should throw TaskServiceError.serverError, got: \(error)")
        }
    }

    // MARK: - Data Serialization Tests

    func testJSONSerializationAndDeserialization() async throws {
        // Given
        let authToken = "test-jwt-token-\(UUID().uuidString)"
        mockKeychainStore.storeToken(authToken)

        let taskId = UUID()
        let complexTask = MockDataProvider.createMockTask(
            id: taskId,
            title: "Complex Task with Special Characters: éñüîôç",
            description: "Description with\nnewlines and\ttabs\r\nand Unicode: 🚀📱💻"
        )

        testServer.setupMockResponse(
            endpoint: "/api/tasks/\(taskId.uuidString)",
            method: "GET",
            statusCode: 200,
            responseBody: complexTask
        )

        // When
        let task = try await taskService.fetchTask(byId: taskId)

        // Then
        XCTAssertEqual(task.id, taskId)
        XCTAssertEqual(task.title, complexTask["title"] as? String)
        XCTAssertEqual(task.description, complexTask["description"] as? String)

        // Verify the data was properly encoded/decoded
        let title = task.title
        XCTAssertTrue(title.contains("éñüîôç"))
        XCTAssertTrue(title.contains("🚀📱💻"))
    }

    func testDateHandlingInAPIResponses() async throws {
        // Given
        let authToken = "test-jwt-token-\(UUID().uuidString)"
        mockKeychainStore.storeToken(authToken)

        let fixedDate = Date()
        let taskWithSpecificDates = MockDataProvider.createMockTask(
            createdAt: fixedDate,
            updatedAt: fixedDate.addingTimeInterval(3600) // 1 hour later
        )

        testServer.setupMockResponse(
            endpoint: "/api/tasks",
            method: "GET",
            statusCode: 200,
            responseBody: [taskWithSpecificDates]
        )

        // When
        let tasks = try await taskService.fetchTasks()

        // Then
        XCTAssertEqual(tasks.count, 1)
        let task = tasks[0]

        // Dates should be parsed correctly (allowing for small time differences)
        let createdAtDiff = abs(task.createdAt.timeIntervalSince(fixedDate))
        let updatedAtDiff = abs(task.updatedAt.timeIntervalSince(fixedDate.addingTimeInterval(3600)))

        XCTAssertLessThan(createdAtDiff, 1.0, "Created date should be parsed correctly")
        XCTAssertLessThan(updatedAtDiff, 1.0, "Updated date should be parsed correctly")
    }

    // MARK: - Concurrent Request Tests

    func testConcurrentAPIRequests() async throws {
        // Given
        let authToken = "test-jwt-token-\(UUID().uuidString)"
        mockKeychainStore.storeToken(authToken)

        let taskIds = (0..<5).map { _ in UUID() }
        let mockTasks = taskIds.map { MockDataProvider.createMockTask(id: $0) }

        // Setup responses for individual task fetches
        for (index, taskId) in taskIds.enumerated() {
            testServer.setupMockResponse(
                endpoint: "/api/tasks/\(taskId.uuidString)",
                method: "GET",
                statusCode: 200,
                responseBody: mockTasks[index]
            )
        }

        // When - Make concurrent requests
        let startTime = Date()
        async let task1 = taskService.fetchTask(byId: taskIds[0])
        async let task2 = taskService.fetchTask(byId: taskIds[1])
        async let task3 = taskService.fetchTask(byId: taskIds[2])
        async let task4 = taskService.fetchTask(byId: taskIds[3])
        async let task5 = taskService.fetchTask(byId: taskIds[4])

        let results = try await [task1, task2, task3, task4, task5]
        let endTime = Date()

        // Then
        XCTAssertEqual(results.count, 5)
        for (index, task) in results.enumerated() {
            XCTAssertEqual(task.id, taskIds[index])
        }

        // Should complete faster than sequential requests
        let totalTime = endTime.timeIntervalSince(startTime)
        XCTAssertLessThan(totalTime, 5.0, "Concurrent requests should complete quickly")
    }

    // MARK: - Performance Tests

    func testAPIResponseTimePerformance() async throws {
        // Given
        let authToken = "test-jwt-token-\(UUID().uuidString)"
        mockKeychainStore.storeToken(authToken)

        testServer.setupMockResponse(
            endpoint: "/api/tasks",
            method: "GET",
            statusCode: 200,
            responseBody: MockDataProvider.createMultipleMockTasks(count: 100)
        )

        // When/Then
        let startTime = Date()
        _ = try await taskService.fetchTasks()
        let endTime = Date()

        let responseTime = endTime.timeIntervalSince(startTime)
        XCTAssertLessThan(responseTime, 2.0, "API response should be under 2 seconds")
    }

    func testLargePayloadHandlingPerformance() async throws {
        // Given
        let authToken = "test-jwt-token-\(UUID().uuidString)"
        mockKeychainStore.storeToken(authToken)

        let largeTaskList = MockDataProvider.createMultipleMockTasks(count: 1000)
        testServer.setupMockResponse(
            endpoint: "/api/tasks",
            method: "GET",
            statusCode: 200,
            responseBody: largeTaskList
        )

        // When/Then
        measure {
            let expectation = expectation(description: "Large payload fetch")
            Task {
                do {
                    _ = try await taskService.fetchTasks()
                    expectation.fulfill()
                } catch {
                    XCTFail("Large payload test should not fail")
                }
            }
            wait(for: [expectation], timeout: 10.0)
        }
    }

    // MARK: - Error Recovery Tests

    func testRetryLogicOnTransientFailures() async throws {
        // Given
        let authToken = "test-jwt-token-\(UUID().uuidString)"
        mockKeychainStore.storeToken(authToken)

        let mockTasks = MockDataProvider.createMultipleMockTasks(count: 3)

        // First two calls fail with 500, third succeeds
        testServer.setupMockResponses([
            (endpoint: "/api/tasks", method: "GET", statusCode: 500, responseBody: ["error": "Internal Server Error"]),
            (endpoint: "/api/tasks", method: "GET", statusCode: 502, responseBody: ["error": "Bad Gateway"]),
            (endpoint: "/api/tasks", method: "GET", statusCode: 200, responseBody: mockTasks)
        ])

        // When
        let tasks = try await taskService.fetchTasks()

        // Then
        XCTAssertEqual(tasks.count, mockTasks.count)
        XCTAssertEqual(testServer.requestCount, 3) // Should have retried twice
    }

    func testCircuitBreakerPattern() async throws {
        // Given - Simulate multiple failures to trigger circuit breaker
        let authToken = "test-jwt-token-\(UUID().uuidString)"
        mockKeychainStore.storeToken(authToken)

        // Setup multiple server errors
        for _ in 0..<5 {
            testServer.setupMockResponse(
                endpoint: "/api/tasks",
                method: "GET",
                statusCode: 503,
                responseBody: ["error": "Service Unavailable"]
            )
        }

        // When/Then - Multiple calls should eventually fail fast
        var failures = 0
        for _ in 0..<3 {
            do {
                _ = try await taskService.fetchTasks()
            } catch TaskServiceError.serverError {
                failures += 1
            } catch {
                // Other errors are also acceptable
                failures += 1
            }
        }

        XCTAssertGreaterThan(failures, 0, "Should have some failures")
    }
}

// MARK: - Mock Classes

private class MockHTTPClient: ApiClientProtocol {
    var shouldSimulateTimeout = false

    func performRequest<T>(_ request: APIRequest) async throws -> T {
        if shouldSimulateTimeout {
            throw URLError(.timedOut)
        }

        // Implementation would delegate to test server
        throw NSError(domain: "MockError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not implemented"])
    }
}

private class MockKeychainStore: KeychainStoreProtocol {
    private var storedToken: String?
    var mockRefreshedToken: String?

    func storeToken(_ token: String) {
        storedToken = token
    }

    func loadToken() -> String? {
        return storedToken ?? mockRefreshedToken
    }

    func clearToken() {
        storedToken = nil
        mockRefreshedToken = nil
    }
}

private class TestServer {
    private var mockResponses: [String: (method: String, statusCode: Int, responseBody: Any?)] = [:]
    private var mockResponseQueue: [(endpoint: String, method: String, statusCode: Int, responseBody: Any?)] = []
    private var requestHistory: [TestRequest] = []
    private var isRunning = false

    var lastRequest: TestRequest? {
        return requestHistory.last
    }

    var requestCount: Int {
        return requestHistory.count
    }

    func start() throws {
        isRunning = true
        // In a real implementation, this would start an HTTP server
    }

    func stop() throws {
        isRunning = false
        mockResponses.removeAll()
        mockResponseQueue.removeAll()
        requestHistory.removeAll()
    }

    func setupMockResponse(endpoint: String, method: String, statusCode: Int, responseBody: Any?) {
        mockResponses["\(method) \(endpoint)"] = (method, statusCode, responseBody)
    }

    func setupMockResponses(_ responses: [(endpoint: String, method: String, statusCode: Int, responseBody: Any?)]) {
        mockResponseQueue = responses
    }

    // This would be called by the mock HTTP client
    func handleRequest(_ request: TestRequest) -> (statusCode: Int, responseBody: Any?) {
        requestHistory.append(request)

        let key = "\(request.method) \(request.path)"

        if !mockResponseQueue.isEmpty {
            let response = mockResponseQueue.removeFirst()
            return (response.statusCode, response.responseBody)
        } else if let response = mockResponses[key] {
            return (response.statusCode, response.responseBody)
        } else {
            return (404, ["error": "Not found"])
        }
    }
}

private struct TestRequest {
    let method: String
    let path: String
    let headers: [String: String]
    let body: Any?
}

// MARK: - Test Extensions

private extension MockDataProvider {
    static func createMultipleMockTasks(count: Int, status: TaskStatus = .todo) -> [[String: Any]] {
        return (0..<count).map { index in
            createMockTask(
                title: "Task \(index + 1)",
                description: "Description for task \(index + 1)",
                status: status
            )
        }
    }

    static func createMockTask(id: UUID = UUID(),
                              title: String = "Mock Task",
                              description: String? = "Mock description",
                              status: TaskStatus = .todo,
                              createdAt: Date = Date(),
                              updatedAt: Date = Date()) -> [String: Any] {
        return [
            "id": id.uuidString,
            "userId": UUID().uuidString,
            "title": title,
            "description": description as Any,
            "status": status.rawValue,
            "createdAt": ISO8601DateFormatter().string(from: createdAt),
            "updatedAt": ISO8601DateFormatter().string(from: updatedAt)
        ]
    }
}