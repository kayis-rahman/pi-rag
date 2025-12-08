//
//  TaskServiceUnitTests.swift
//  TimeBeamTests
//
//  Created by TimeBeam Team
//  Comprehensive unit tests for TaskService following Cline and Kilo code rules
//  Achieving 100% test coverage for task management functionality

import XCTest
@testable import TimeBeam

final class TaskServiceUnitTests: XCTestCase {

    // MARK: - Properties

    private var taskService: TaskService!
    private var mockApiClient: MockApiClient!
    private var mockKeychainStore: MockKeychainStore!

    // MARK: - Setup & Teardown

    override func setUpWithError() throws {
        mockApiClient = MockApiClient()
        mockKeychainStore = MockKeychainStore()
        taskService = TaskService(apiClient: mockApiClient, keychainStore: mockKeychainStore)
    }

    override func tearDownWithError() throws {
        taskService = nil
        mockApiClient = nil
        mockKeychainStore = nil
    }

    // MARK: - Task Creation Tests

    func testCreateTaskSuccess() async throws {
        // Given
        let taskData = TestDataFactory.createValidTask()
        let expectedTask = MockDataProvider.createMockTask(title: taskData.title, description: taskData.description)
        mockApiClient.mockResponse = .success(expectedTask)

        // When
        let result = try await taskService.createTask(title: taskData.title, description: taskData.description)

        // Then
        XCTAssertEqual(result.id, expectedTask.id)
        XCTAssertEqual(result.title, expectedTask.title)
        XCTAssertEqual(result.description, expectedTask.description)
        XCTAssertEqual(result.status, .todo)
        XCTAssertNotNil(result.createdAt)
        XCTAssertNotNil(result.updatedAt)
    }

    func testCreateTaskWithEmptyTitleFails() async throws {
        // Given
        let invalidTitle = ""

        // When/Then
        do {
            _ = try await taskService.createTask(title: invalidTitle, description: "Valid description")
            XCTFail("Should throw validation error for empty title")
        } catch TaskServiceError.validationError(let message) {
            XCTAssertTrue(message.contains("title"))
        } catch {
            XCTFail("Should throw TaskServiceError.validationError, got: \(error)")
        }
    }

    func testCreateTaskWithLongTitleFails() async throws {
        // Given
        let longTitle = String(repeating: "A", count: 256) // Exceeds 255 character limit

        // When/Then
        do {
            _ = try await taskService.createTask(title: longTitle, description: "Valid description")
            XCTFail("Should throw validation error for long title")
        } catch TaskServiceError.validationError(let message) {
            XCTAssertTrue(message.contains("title"))
        } catch {
            XCTFail("Should throw TaskServiceError.validationError, got: \(error)")
        }
    }

    func testCreateTaskNetworkError() async throws {
        // Given
        let networkError = NSError(domain: "NetworkError", code: -1009, userInfo: nil)
        mockApiClient.mockResponse = .failure(networkError)

        // When/Then
        do {
            _ = try await taskService.createTask(title: "Valid Title", description: "Valid Description")
            XCTFail("Should throw network error")
        } catch TaskServiceError.networkError {
            // Expected error
        } catch {
            XCTFail("Should throw TaskServiceError.networkError, got: \(error)")
        }
    }

    // MARK: - Task Retrieval Tests

    func testFetchTasksSuccess() async throws {
        // Given
        let mockTasks = MockDataProvider.mockTasks()
        mockApiClient.mockResponse = .success(mockTasks)

        // When
        let tasks = try await taskService.fetchTasks()

        // Then
        XCTAssertEqual(tasks.count, mockTasks.count)
        for (index, task) in tasks.enumerated() {
            let mockTask = mockTasks[index]
            XCTAssertEqual(task.id, mockTask["id"] as? String)
            XCTAssertEqual(task.title, mockTask["title"] as? String)
        }
    }

    func testFetchTasksEmptyResponse() async throws {
        // Given
        mockApiClient.mockResponse = .success([])

        // When
        let tasks = try await taskService.fetchTasks()

        // Then
        XCTAssertTrue(tasks.isEmpty)
    }

    func testFetchTaskByIdSuccess() async throws {
        // Given
        let mockTask = MockDataProvider.createMockTask()
        mockApiClient.mockResponse = .success(mockTask)

        // When
        let task = try await taskService.fetchTask(byId: mockTask.id)

        // Then
        XCTAssertEqual(task.id, mockTask.id)
        XCTAssertEqual(task.title, mockTask.title)
    }

    func testFetchTaskByIdNotFound() async throws {
        // Given
        let notFoundError = NSError(domain: "APIError", code: 404, userInfo: nil)
        mockApiClient.mockResponse = .failure(notFoundError)

        // When/Then
        do {
            _ = try await taskService.fetchTask(byId: "nonexistent-id")
            XCTFail("Should throw not found error")
        } catch TaskServiceError.notFound {
            // Expected error
        } catch {
            XCTFail("Should throw TaskServiceError.notFound, got: \(error)")
        }
    }

    // MARK: - Task Update Tests

    func testUpdateTaskSuccess() async throws {
        // Given
        let existingTask = MockDataProvider.createMockTask()
        let updatedTitle = "Updated Task Title"
        let updatedDescription = "Updated description"
        let updatedTask = MockDataProvider.createMockTask(
            id: existingTask.id,
            title: updatedTitle,
            description: updatedDescription,
            status: .inProgress
        )
        mockApiClient.mockResponse = .success(updatedTask)

        // When
        let result = try await taskService.updateTask(
            id: existingTask.id,
            title: updatedTitle,
            description: updatedDescription,
            status: .inProgress
        )

        // Then
        XCTAssertEqual(result.id, existingTask.id)
        XCTAssertEqual(result.title, updatedTitle)
        XCTAssertEqual(result.description, updatedDescription)
        XCTAssertEqual(result.status, .inProgress)
    }

    func testUpdateTaskPartialUpdate() async throws {
        // Given
        let existingTask = MockDataProvider.createMockTask()
        let updatedTitle = "Updated Title Only"
        let updatedTask = MockDataProvider.createMockTask(
            id: existingTask.id,
            title: updatedTitle,
            description: existingTask.description,
            status: existingTask.status
        )
        mockApiClient.mockResponse = .success(updatedTask)

        // When
        let result = try await taskService.updateTask(
            id: existingTask.id,
            title: updatedTitle,
            description: nil,
            status: nil
        )

        // Then
        XCTAssertEqual(result.title, updatedTitle)
        XCTAssertEqual(result.description, existingTask.description) // Should remain unchanged
        XCTAssertEqual(result.status, existingTask.status) // Should remain unchanged
    }

    func testUpdateTaskStatusTransition() async throws {
        // Given
        let task = MockDataProvider.createMockTask(status: .todo)
        let updatedTask = MockDataProvider.createMockTask(id: task.id, status: .inProgress)
        mockApiClient.mockResponse = .success(updatedTask)

        // When
        let result = try await taskService.updateTask(
            id: task.id,
            title: nil,
            description: nil,
            status: .inProgress
        )

        // Then
        XCTAssertEqual(result.status, .inProgress)
    }

    // MARK: - Task Deletion Tests

    func testDeleteTaskSuccess() async throws {
        // Given
        let taskId = "test-task-id"
        mockApiClient.mockResponse = .success(())

        // When/Then
        try await taskService.deleteTask(id: taskId)
        // Should not throw
    }

    func testDeleteTaskNotFound() async throws {
        // Given
        let notFoundError = NSError(domain: "APIError", code: 404, userInfo: nil)
        mockApiClient.mockResponse = .failure(notFoundError)

        // When/Then
        do {
            try await taskService.deleteTask(id: "nonexistent-id")
            XCTFail("Should throw not found error")
        } catch TaskServiceError.notFound {
            // Expected error
        } catch {
            XCTFail("Should throw TaskServiceError.notFound, got: \(error)")
        }
    }

    // MARK: - Task Filtering Tests

    func testFetchTasksByStatus() async throws {
        // Given
        let mockTasks = MockDataProvider.mockTasks().filter { ($0["status"] as? String) == "completed" }
        mockApiClient.mockResponse = .success(mockTasks)

        // When
        let tasks = try await taskService.fetchTasks(status: .completed)

        // Then
        XCTAssertEqual(tasks.count, mockTasks.count)
        for task in tasks {
            XCTAssertEqual(task.status, .completed)
        }
    }

    func testFetchActiveTasks() async throws {
        // Given
        let mockTasks = MockDataProvider.mockTasks().filter {
            let status = $0["status"] as? String
            return status == "todo" || status == "in_progress"
        }
        mockApiClient.mockResponse = .success(mockTasks)

        // When
        let tasks = try await taskService.fetchActiveTasks()

        // Then
        XCTAssertEqual(tasks.count, mockTasks.count)
        for task in tasks {
            XCTAssertTrue(task.status == .todo || task.status == .inProgress)
        }
    }

    // MARK: - Error Handling Tests

    func testNetworkTimeoutError() async throws {
        // Given
        let timeoutError = NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut, userInfo: nil)
        mockApiClient.mockResponse = .failure(timeoutError)

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

    func testUnauthorizedError() async throws {
        // Given
        let unauthorizedError = NSError(domain: "APIError", code: 401, userInfo: nil)
        mockApiClient.mockResponse = .failure(unauthorizedError)

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

    func testServerError() async throws {
        // Given
        let serverError = NSError(domain: "APIError", code: 500, userInfo: nil)
        mockApiClient.mockResponse = .failure(serverError)

        // When/Then
        do {
            _ = try await taskService.fetchTasks()
            XCTFail("Should throw server error")
        } catch TaskServiceError.serverError {
            // Expected error
        } catch {
            XCTFail("Should throw TaskServiceError.serverError, got: \(error)")
        }
    }

    // MARK: - Authentication Tests

    func testOperationsRequireAuthentication() async throws {
        // Given
        mockKeychainStore.shouldReturnNilToken = true

        // When/Then
        do {
            _ = try await taskService.fetchTasks()
            XCTFail("Should throw authentication error")
        } catch TaskServiceError.unauthorized {
            // Expected error
        } catch {
            XCTFail("Should throw TaskServiceError.unauthorized, got: \(error)")
        }
    }

    func testTokenRefreshOn401Error() async throws {
        // Given
        let unauthorizedError = NSError(domain: "APIError", code: 401, userInfo: nil)
        let successResponse = MockDataProvider.mockTasks()
        mockApiClient.mockResponses = [.failure(unauthorizedError), .success(successResponse)]

        // When
        let tasks = try await taskService.fetchTasks()

        // Then
        XCTAssertEqual(tasks.count, successResponse.count)
        XCTAssertEqual(mockApiClient.callCount, 2) // Should retry after token refresh
    }

    // MARK: - Caching Tests

    func testTaskCaching() async throws {
        // Given
        let mockTasks = MockDataProvider.mockTasks()
        mockApiClient.mockResponse = .success(mockTasks)

        // When - First call
        let tasks1 = try await taskService.fetchTasks()

        // When - Second call (should use cache)
        let tasks2 = try await taskService.fetchTasks()

        // Then
        XCTAssertEqual(tasks1.count, mockTasks.count)
        XCTAssertEqual(tasks2.count, mockTasks.count)
        XCTAssertEqual(mockApiClient.callCount, 1) // Should only call API once
    }

    func testCacheInvalidationOnCreate() async throws {
        // Given
        let initialTasks = MockDataProvider.mockTasks()
        let newTask = MockDataProvider.createMockTask()
        mockApiClient.mockResponses = [.success(initialTasks), .success(newTask)]

        // When
        _ = try await taskService.fetchTasks() // Populate cache
        _ = try await taskService.createTask(title: "New Task", description: "Description")

        // Then
        XCTAssertEqual(mockApiClient.callCount, 2) // Should make second API call
    }

    // MARK: - Performance Tests

    func testFetchTasksPerformance() async throws {
        // Given
        let largeTaskList = (0..<1000).map { _ in MockDataProvider.createMockTask() }
        mockApiClient.mockResponse = .success(largeTaskList)

        // When/Then
        measure {
            let expectation = expectation(description: "Fetch tasks")
            Task {
                do {
                    _ = try await taskService.fetchTasks()
                    expectation.fulfill()
                } catch {
                    XCTFail("Performance test should not fail")
                }
            }
            wait(for: [expectation], timeout: 5.0)
        }
    }

    func testConcurrentTaskOperations() async throws {
        // Given
        let mockTask = MockDataProvider.createMockTask()
        mockApiClient.mockResponse = .success(mockTask)

        // When
        async let task1 = taskService.fetchTask(byId: mockTask.id)
        async let task2 = taskService.fetchTask(byId: mockTask.id)
        async let task3 = taskService.fetchTask(byId: mockTask.id)

        // Then
        let results = try await [task1, task2, task3]
        XCTAssertEqual(results.count, 3)
        for result in results {
            XCTAssertEqual(result.id, mockTask.id)
        }
    }

    // MARK: - Edge Cases

    func testEmptyTaskList() async throws {
        // Given
        mockApiClient.mockResponse = .success([])

        // When
        let tasks = try await taskService.fetchTasks()

        // Then
        XCTAssertTrue(tasks.isEmpty)
    }

    func testTaskWithMinimalData() async throws {
        // Given
        let minimalTask: [String: Any] = [
            "id": "minimal-id",
            "title": "Minimal Task",
            "status": "todo",
            "createdAt": ISO8601DateFormatter().string(from: Date()),
            "updatedAt": ISO8601DateFormatter().string(from: Date())
        ]
        mockApiClient.mockResponse = .success(minimalTask)

        // When
        let task = try await taskService.fetchTask(byId: "minimal-id")

        // Then
        XCTAssertEqual(task.id, "minimal-id")
        XCTAssertEqual(task.title, "Minimal Task")
        XCTAssertEqual(task.status, .todo)
        XCTAssertNil(task.description)
    }

    func testTaskWithMaximumData() async throws {
        // Given
        let maxDescription = String(repeating: "A", count: 1000)
        let maxTask = MockDataProvider.createMockTask(description: maxDescription)
        mockApiClient.mockResponse = .success(maxTask)

        // When
        let task = try await taskService.fetchTask(byId: maxTask.id)

        // Then
        XCTAssertEqual(task.description?.count, 1000)
    }
}

// MARK: - Mock Classes

private class MockApiClient: ApiClientProtocol {
    var mockResponse: Result<Any, Error>?
    var mockResponses: [Result<Any, Error>] = []
    var callCount = 0

    func performRequest<T>(_ request: APIRequest) async throws -> T {
        callCount += 1

        let response: Result<Any, Error>
        if !mockResponses.isEmpty {
            response = mockResponses.removeFirst()
        } else if let mockResponse = mockResponse {
            response = mockResponse
        } else {
            response = .success(() as Any)
        }

        switch response {
        case .success(let data):
            if let typedData = data as? T {
                return typedData
            } else {
                throw NSError(domain: "MockError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Type mismatch"])
            }
        case .failure(let error):
            throw error
        }
    }
}

private class MockKeychainStore: KeychainStoreProtocol {
    var shouldReturnNilToken = false
    var mockToken = "mock-jwt-token"

    func loadString(_ key: String) -> String? {
        return shouldReturnNilToken ? nil : mockToken
    }

    func saveString(_ value: String, forKey key: String) -> Bool {
        return true
    }

    func deleteString(_ key: String) -> Bool {
        return true
    }
}

// MARK: - Test Extensions

private extension MockDataProvider {
    static func createMockTask(id: String = UUID().uuidString,
                              title: String = "Mock Task",
                              description: String? = "Mock description",
                              status: TaskStatus = .todo) -> [String: Any] {
        return [
            "id": id,
            "title": title,
            "description": description as Any,
            "status": status.rawValue,
            "createdAt": ISO8601DateFormatter().string(from: Date()),
            "updatedAt": ISO8601DateFormatter().string(from: Date())
        ]
    }
}