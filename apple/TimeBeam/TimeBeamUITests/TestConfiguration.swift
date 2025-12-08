//
//  TestConfiguration.swift
//  TimeBeamUITests
//
//  Created by TimeBeam Team
//  Test configuration and environment settings for E2E tests
//

import Foundation

/// Configuration for E2E tests
struct TestConfiguration {
    // Timing constants
    static let defaultTimeout: TimeInterval = 10.0
    static let quickTimeout: TimeInterval = 3.0
    static let extendedTimeout: TimeInterval = 30.0

    // Test environment settings
    static let isE2ETesting: Bool = {
        return ProcessInfo.processInfo.environment["E2E_TESTING"] == "true"
    }()

    // Backend configuration for E2E tests
    static let e2eBackendURL: String = {
        return ProcessInfo.processInfo.environment["E2E_BACKEND_URL"] ?? "http://localhost:8081"
    }()

    // Test user credentials
    static let testUserEmail = "test@example.com"
    static let testUserDisplayName = "Test User"

    static let testUser2Email = "test2@example.com"
    static let testUser2DisplayName = "Test User 2"

    // Test data IDs (matching backend seeder)
    struct TestDataIDs {
        static let testUserID = "550e8400-e29b-41d4-a716-446655440000"
        static let testUser2ID = "550e8400-e29b-41d4-a716-446655440001"

        // Task IDs
        static let documentationTaskID = "550e8400-e29b-41d4-a716-446655440010"
        static let authTaskID = "550e8400-e29b-41d4-a716-446655440011"
        static let cicdTaskID = "550e8400-e29b-41d4-a716-446655440012"
        static let uiTaskID = "550e8400-e29b-41d4-a716-446655440013"

        // Device IDs
        static let iosSimulatorDeviceID = "ios-simulator-test-device"
        static let macosDeviceID = "macos-test-device"
    }

    // UI Test data expectations
    struct ExpectedData {
        static let initialTaskCount = 4
        static let initialSessionCount = 4
        static let initialCompletedTasks = 1
        static let initialInProgressTasks = 1
        static let initialTodoTasks = 2
    }
}

/// Extension to provide test configuration methods
extension XCUIApplication {

    /// Launch the app with E2E test configuration
    func launchForE2ETesting() -> XCUIApplication {
        var launchEnvironment = [String: String]()
        launchEnvironment["E2E_TESTING"] = "true"
        launchEnvironment["E2E_BACKEND_URL"] = TestConfiguration.e2eBackendURL

        launchEnvironment["API_BASE_URL"] = TestConfiguration.e2eBackendURL

        launchArguments = ["--reset-data"]
        launchEnvironment.forEach { key, value in
            launchEnvironment[key] = value
        }

        return self
    }

    /// Navigate to a specific tab by name
    func navigateToTab(_ tabName: String) -> XCUIApplication {
        let tabBar = tabBars.firstMatch
        let tabButton = tabBar.buttons[tabName]
        XCTAssertTrue(tabButton.waitForExistence(timeout: TestConfiguration.defaultTimeout),
                     "Tab '\(tabName)' should be available")
        tabButton.tap()
        return self
    }

    /// Wait for the app to be fully ready after launch
    func waitForAppReady() -> XCUIApplication {
        // Wait for main timer view to appear
        let timerView = otherElements["CircularTimerView"]
        XCTAssertTrue(timerView.waitForExistence(timeout: TestConfiguration.extendedTimeout),
                     "App should be ready within timeout")
        return self
    }
}

/// Test base class for E2E tests
class TimeBeamE2ETestBase: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app = app.launchForE2ETesting()
        app.waitForAppReady()

        try super.setUpWithError()
    }

    override func tearDownWithError() throws {
        if let failure = testRun?.failureCount, failure > 0 {
            // Take screenshot on failure
            let screenshot = XCUIScreen.main.screenshot()
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = "Screenshot on failure: \(name)"
            attachment.lifetime = .deleteOnSuccess
            add(attachment)
        }

        app.terminate()
        try super.tearDownWithError()
    }

    /// Helper method to perform authenticated actions
    func performAuthenticatedAction(email: String = TestConfiguration.testUserEmail,
                                   action: () -> Void) {
        // Ensure we're authenticated
        ensureAuthenticated(with: email)

        // Perform the action
        action()
    }

    /// Ensure the app is authenticated with the specified user
    private func ensureAuthenticated(with email: String) {
        // Check if we need to log in
        // This would be implemented based on your app's authentication flow
        // For now, assume the test data seeder provides authentication
    }

    /// Wait for network operation to complete
    func waitForNetworkOperation(timeout: TimeInterval = TestConfiguration.defaultTimeout) {
        // Simple wait for network operations
        // In a real implementation, you might use network stubs or monitoring
        Thread.sleep(forTimeInterval: 1.0)
    }
}
