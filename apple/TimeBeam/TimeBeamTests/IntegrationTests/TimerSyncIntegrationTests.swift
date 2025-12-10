//
//  TimerSyncIntegrationTests.swift
//  TimeBeamTests
//
//  Created by TimeBeam Team
//  Comprehensive integration tests for timer synchronization and device registration
//  Testing full sync workflows with mocked backend and device interactions
//  Following Cline and Kilo code rules for integration testing

import XCTest
@testable import TimeBeam

final class TimerSyncIntegrationTests: XCTestCase {

    // MARK: - Properties

    private var timerSyncManager: TimerSyncManager!
    private var mockApiClient: MockApiClient!
    private var mockKeychainStore: MockKeychainStore!
    private var testServer: TestServer!
    private var mockTimer: MockPomodoroTimer!

    // MARK: - Setup & Teardown

    override func setUpWithError() throws {
        mockApiClient = MockApiClient()
        mockKeychainStore = MockKeychainStore()
        testServer = TestServer()
        mockTimer = MockPomodoroTimer()

        timerSyncManager = TimerSyncManager.shared
        timerSyncManager.configure(with: mockTimer)

        // Start test server
        try testServer.start()
    }

    override func tearDownWithError() throws {
        try testServer.stop()
        testServer = nil
        timerSyncManager = nil
        mockApiClient = nil
        mockKeychainStore = nil
        mockTimer = nil
    }

    // MARK: - Device Registration Integration Tests

    func testDeviceRegistrationFlow() async throws {
        // Given - Setup authenticated user
        let authToken = "test-jwt-token-\(UUID().uuidString)"
        mockKeychainStore.storeToken(authToken)

        let deviceRegistration = ApiClient.DeviceRegistrationDto(
            deviceId: timerSyncManager.deviceId,
            deviceName: "Test iPhone",
            deviceType: "ios",
            platformVersion: "18.0",
            appVersion: "1.0.0",
            fcmToken: nil
        )

        // Setup mock server response
        testServer.setupMockResponse(
            endpoint: "/api/devices/register",
            method: "POST",
            statusCode: 200,
            responseBody: ["success": true]
        )

        // When - Trigger device registration
        await timerSyncManager.smartSyncWithBackend()

        // Then - Verify registration was attempted
        let lastRequest = testServer.lastRequest
        XCTAssertEqual(lastRequest?.method, "POST")
        XCTAssertEqual(lastRequest?.path, "/api/devices/register")

        // Verify request body
        let requestBody = lastRequest?.body as? [String: Any]
        XCTAssertEqual(requestBody?["deviceId"] as? String, deviceRegistration.deviceId)
        XCTAssertEqual(requestBody?["deviceName"] as? String, deviceRegistration.deviceName)
        XCTAssertEqual(requestBody?["deviceType"] as? String, deviceRegistration.deviceType)

        // Verify authorization header
        XCTAssertEqual(lastRequest?.headers["Authorization"], "Bearer \(authToken)")
    }

    func testDeviceRegistrationWithAPNToken() async throws {
        // Given - Setup authenticated user with APN token
        let authToken = "test-jwt-token-\(UUID().uuidString)"
        mockKeychainStore.storeToken(authToken)

        let apnsToken = "test-apns-token-12345"
        mockApiClient.mockApnsToken = apnsToken

        // Setup mock responses for both device registration and APN token update
        testServer.setupMockResponses([
            (endpoint: "/api/devices/register", method: "POST", statusCode: 200, responseBody: ["success": true]),
            (endpoint: "/api/sessions/devices/apns-token", method: "POST", statusCode: 200, responseBody: ["success": true])
        ])

        // When - Trigger device registration
        await timerSyncManager.smartSyncWithBackend()

        // Then - Verify both requests were made
        XCTAssertEqual(testServer.requestCount, 2)

        // Find APN token update request
        let apnRequests = testServer.requestHistory.filter { $0.path.contains("apns-token") }
        XCTAssertEqual(apnRequests.count, 1)

        let apnRequest = apnRequests[0]
        XCTAssertEqual(apnRequest.method, "POST")

        // Verify APN token in query parameters
        let queryParams = URLComponents(string: "?\(apnRequest.path.split(separator: "?").last ?? "")")?.queryItems
        XCTAssertEqual(queryParams?.first(where: { $0.name == "apnsToken" })?.value, apnsToken)
        XCTAssertEqual(queryParams?.first(where: { $0.name == "deviceId" })?.value, timerSyncManager.deviceId)
    }

    func testDeviceRegistrationFailureHandling() async throws {
        // Given - Setup authenticated user with failing registration
        let authToken = "test-jwt-token-\(UUID().uuidString)"
        mockKeychainStore.storeToken(authToken)

        testServer.setupMockResponse(
            endpoint: "/api/devices/register",
            method: "POST",
            statusCode: 500,
            responseBody: ["error": "Internal Server Error"]
        )

        // When - Trigger device registration
        await timerSyncManager.smartSyncWithBackend()

        // Then - Verify registration was attempted but sync continued
        let lastRequest = testServer.lastRequest
        XCTAssertEqual(lastRequest?.method, "POST")
        XCTAssertEqual(lastRequest?.path, "/api/devices/register")

        // Device should still be marked as registered for future attempts
        // (This tests that registration failures don't break the sync flow)
    }

    // MARK: - Timer Synchronization Integration Tests

    func testTimerStatePushToBackend() async throws {
        // Given - Setup authenticated user and running timer
        let authToken = "test-jwt-token-\(UUID().uuidString)"
        mockKeychainStore.storeToken(authToken)

        mockTimer.phase = .work
        mockTimer.isRunning = true
        mockTimer.remainingSeconds = 1500
        mockTimer.workDuration = 1500
        mockTimer.breakDuration = 300

        testServer.setupMockResponse(
            endpoint: "/api/sessions/timer/state",
            method: "POST",
            statusCode: 200,
            responseBody: ["success": true]
        )

        // When - Trigger timer sync
        await timerSyncManager.smartSyncWithBackend()

        // Then - Verify timer state was pushed
        let lastRequest = testServer.lastRequest
        XCTAssertEqual(lastRequest?.method, "POST")
        XCTAssertEqual(lastRequest?.path, "/api/sessions/timer/state")

        // Verify request body contains timer state
        let requestBody = lastRequest?.body as? [String: Any]
        XCTAssertEqual(requestBody?["phase"] as? String, "work")
        XCTAssertEqual(requestBody?["isRunning"] as? Bool, true)
        XCTAssertEqual(requestBody?["remainingSeconds"] as? Int, 1500)
        XCTAssertEqual(requestBody?["deviceId"] as? String, timerSyncManager.deviceId)
    }

    func testTimerStatePullFromBackend() async throws {
        // Given - Setup authenticated user with backend timer state
        let authToken = "test-jwt-token-\(UUID().uuidString)"
        mockKeychainStore.storeToken(authToken)

        let backendState: [String: Any] = [
            "phase": "break",
            "remainingSeconds": 250,
            "isRunning": false,
            "workDuration": 1500,
            "breakDuration": 300,
            "longBreakDuration": 900,
            "autoStartNextSession": true,
            "shortBreaksCompleted": 2,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "deviceId": UUID().uuidString
        ]

        testServer.setupMockResponses([
            (endpoint: "/api/devices/register", method: "POST", statusCode: 200, responseBody: ["success": true]),
            (endpoint: "/api/sessions/timer/state", method: "GET", statusCode: 200, responseBody: backendState)
        ])

        // When - Trigger smart sync
        await timerSyncManager.smartSyncWithBackend()

        // Then - Verify backend state was applied to local timer
        XCTAssertEqual(mockTimer.phase, .break)
        XCTAssertEqual(mockTimer.remainingSeconds, 250)
        XCTAssertEqual(mockTimer.isRunning, false)
        XCTAssertEqual(mockTimer.workDuration, 1500)
        XCTAssertEqual(mockTimer.breakDuration, 300)
        XCTAssertEqual(mockTimer.longBreakDuration, 900)
        XCTAssertEqual(mockTimer.autoStartNextSession, true)
        XCTAssertEqual(mockTimer.shortBreaksCompleted, 2)
    }

    func testTimerActionSync() async throws {
        // Given - Setup authenticated user
        let authToken = "test-jwt-token-\(UUID().uuidString)"
        mockKeychainStore.storeToken(authToken)

        mockTimer.phase = .work
        mockTimer.remainingSeconds = 1500

        testServer.setupMockResponse(
            endpoint: "/api/sessions/timer/action",
            method: "POST",
            statusCode: 200,
            responseBody: ["success": true]
        )

        // When - Trigger timer action
        timerSyncManager.syncAction(.pause)

        // Wait for async operation
        try await Task.sleep(for: .nanoseconds(500_000_000)) // 0.5 seconds

        // Then - Verify action was synced
        let lastRequest = testServer.lastRequest
        XCTAssertEqual(lastRequest?.method, "POST")
        XCTAssertEqual(lastRequest?.path, "/api/sessions/timer/action")

        let requestBody = lastRequest?.body as? [String: Any]
        XCTAssertEqual(requestBody?["action"] as? String, "pause")
        XCTAssertEqual(requestBody?["deviceId"] as? String, timerSyncManager.deviceId)
        XCTAssertEqual(requestBody?["phase"] as? String, "work")
        XCTAssertEqual(requestBody?["remainingSeconds"] as? Int, 1500)
    }

    // MARK: - Cross-Device Synchronization Tests

    func testIncomingTimerActionFromAnotherDevice() async throws {
        // Given - Setup timer in initial state
        mockTimer.phase = .work
        mockTimer.isRunning = true

        let otherDeviceId = UUID().uuidString
        let timestamp = Date()

        // When - Simulate incoming action from another device
        timerSyncManager.handleIncomingAction(.pause, from: otherDeviceId, timestamp: timestamp)

        // Then - Verify local timer was updated
        XCTAssertEqual(mockTimer.phase, .work)
        XCTAssertEqual(mockTimer.isRunning, false) // Should be paused
    }

    func testIgnoreOwnTimerActions() async throws {
        // Given - Setup timer in initial state
        mockTimer.phase = .work
        mockTimer.isRunning = true

        let ownDeviceId = timerSyncManager.deviceId
        let timestamp = Date()

        // When - Simulate incoming action from own device
        timerSyncManager.handleIncomingAction(.pause, from: ownDeviceId, timestamp: timestamp)

        // Then - Verify local timer was NOT updated (should ignore own actions)
        XCTAssertEqual(mockTimer.phase, .work)
        XCTAssertEqual(mockTimer.isRunning, true) // Should remain running
    }

    func testOutdatedTimerActionIgnored() async throws {
        // Given - Setup timer and set last action timestamp to now
        mockTimer.phase = .work
        mockTimer.isRunning = true

        let otherDeviceId = UUID().uuidString
        let oldTimestamp = Date().addingTimeInterval(-60) // 1 minute ago

        // First set a recent timestamp
        timerSyncManager.handleIncomingAction(.start, from: otherDeviceId, timestamp: Date())

        // When - Try to apply an older action
        timerSyncManager.handleIncomingAction(.pause, from: otherDeviceId, timestamp: oldTimestamp)

        // Then - Verify old action was ignored
        XCTAssertEqual(mockTimer.isRunning, true) // Should still be running
    }

    // MARK: - APN Notification Integration Tests

    func testAPNNotificationSentOnTimerAction() async throws {
        // Given - Setup authenticated user
        let authToken = "test-jwt-token-\(UUID().uuidString)"
        mockKeychainStore.storeToken(authToken)

        mockTimer.phase = .work
        mockTimer.remainingSeconds = 1500

        testServer.setupMockResponses([
            (endpoint: "/api/sessions/timer/action", method: "POST", statusCode: 200, responseBody: ["success": true]),
            (endpoint: "/api/notifications/send", method: "POST", statusCode: 200, responseBody: ["success": true])
        ])

        // When - Trigger timer action
        timerSyncManager.syncAction(.pause)

        // Wait for async operations
        try await Task.sleep(for: .nanoseconds(1_000_000_000)) // 1 second

        // Then - Verify both action sync and APN notification were sent
        XCTAssertEqual(testServer.requestCount, 2)

        let notificationRequests = testServer.requestHistory.filter { $0.path.contains("notifications") }
        XCTAssertEqual(notificationRequests.count, 1)

        let notificationRequest = notificationRequests[0]
        let requestBody = notificationRequest.body as? [String: Any]
        XCTAssertEqual(requestBody?["type"] as? String, "timer_sync")

        let actionData = requestBody?["action"] as? [String: Any]
        XCTAssertEqual(actionData?["action"] as? String, "pause")
        XCTAssertEqual(actionData?["deviceId"] as? String, timerSyncManager.deviceId)
    }

    // MARK: - Error Handling and Recovery Tests

    func testNetworkFailureRecovery() async throws {
        // Given - Setup authenticated user with initial network failure
        let authToken = "test-jwt-token-\(UUID().uuidString)"
        mockKeychainStore.storeToken(authToken)

        testServer.setupMockResponses([
            (endpoint: "/api/devices/register", method: "POST", statusCode: 500, responseBody: ["error": "Server Error"]),
            (endpoint: "/api/devices/register", method: "POST", statusCode: 200, responseBody: ["success": true"]) // Retry succeeds
        ])

        // When - Trigger multiple sync attempts
        await timerSyncManager.smartSyncWithBackend()
        await timerSyncManager.smartSyncWithBackend()

        // Then - Verify retry logic worked
        XCTAssertEqual(testServer.requestCount, 2)
    }

    func testConcurrentSyncOperationsPrevented() async throws {
        // Given - Setup authenticated user
        let authToken = "test-jwt-token-\(UUID().uuidString)"
        mockKeychainStore.storeToken(authToken)

        testServer.setupMockResponse(
            endpoint: "/api/devices/register",
            method: "POST",
            statusCode: 200,
            responseBody: ["success": true]
        )

        // When - Trigger multiple concurrent sync operations
        async let sync1 = timerSyncManager.smartSyncWithBackend()
        async let sync2 = timerSyncManager.smartSyncWithBackend()
        async let sync3 = timerSyncManager.smartSyncWithBackend()

        await [sync1, sync2, sync3]

        // Then - Only one sync operation should have proceeded
        XCTAssertEqual(testServer.requestCount, 1)
    }

    // MARK: - Performance Tests

    func testTimerSyncPerformance() async throws {
        // Given - Setup authenticated user
        let authToken = "test-jwt-token-\(UUID().uuidString)"
        mockKeychainStore.storeToken(authToken)

        testServer.setupMockResponses([
            (endpoint: "/api/devices/register", method: "POST", statusCode: 200, responseBody: ["success": true]),
            (endpoint: "/api/sessions/timer/state", method: "GET", statusCode: 200, responseBody: [
                "phase": "work",
                "remainingSeconds": 1500,
                "isRunning": true,
                "workDuration": 1500,
                "breakDuration": 300,
                "longBreakDuration": 900,
                "autoStartNextSession": true,
                "shortBreaksCompleted": 0,
                "timestamp": ISO8601DateFormatter().string(from: Date()),
                "deviceId": UUID().uuidString
            ])
        ])

        // When/Then - Measure sync performance
        measure {
            let expectation = expectation(description: "Timer sync performance")
            Task {
                await timerSyncManager.smartSyncWithBackend()
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 5.0)
        }
    }
}

// MARK: - Mock Classes

private class MockApiClient: ApiClientProtocol {
    var mockApnsToken: String?

    func performRequest<T>(_ request: APIRequest) async throws -> T {
        throw NSError(domain: "MockError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not implemented"])
    }
}

private class MockKeychainStore: KeychainStoreProtocol {
    private var storedToken: String?

    func storeToken(_ token: String) {
        storedToken = token
    }

    func loadToken() -> String? {
        return storedToken
    }

    func clearToken() {
        storedToken = nil
    }
}

private class MockPomodoroTimer: PomodoroTimer {
    var phase: Phase = .work
    var isRunning: Bool = false
    var remainingSeconds: Int = 1500
    var workDuration: Int = 1500
    var breakDuration: Int = 300
    var longBreakDuration: Int = 900
    var autoStartNextSession: Bool = true
    var shortBreaksCompleted: Int = 0

    override func applySyncedState(phase: Phase, remainingSeconds: Int, isRunning: Bool, workDuration: Int, breakDuration: Int, longBreakDuration: Int, autoStartNextSession: Bool, shortBreaksCompleted: Int) {
        self.phase = phase
        self.remainingSeconds = remainingSeconds
        self.isRunning = isRunning
        self.workDuration = workDuration
        self.breakDuration = breakDuration
        self.longBreakDuration = longBreakDuration
        self.autoStartNextSession = autoStartNextSession
        self.shortBreaksCompleted = shortBreaksCompleted
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

    var requestHistory: [TestRequest] {
        return requestHistory
    }

    func start() throws {
        isRunning = true
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