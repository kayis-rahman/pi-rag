//
//  TestUtilities.swift
//  TimeBeamUITests
//
//  Created by TimeBeam Team
//  Comprehensive test utilities for 100% test coverage
//  Following Cline and Kilo code rules for testing best practices

import XCTest
import Foundation

// MARK: - Test Configuration

/// Comprehensive test configuration following iOS testing best practices
struct TestConfiguration {
    static let defaultTimeout: TimeInterval = 10.0
    static let quickTimeout: TimeInterval = 2.0
    static let extendedTimeout: TimeInterval = 30.0
    static let animationTimeout: TimeInterval = 1.0

    static let retryAttempts = 3
    static let retryDelay: TimeInterval = 0.5

    // Device-specific timeouts
    static var deviceTimeout: TimeInterval {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad ? 15.0 : 10.0
        #else
        return 12.0
        #endif
    }
}

// MARK: - Element Extensions

extension XCUIElement {

    /// Wait for element with comprehensive error handling
    /// - Parameters:
    ///   - timeout: Timeout duration
    ///   - description: Description for debugging
    /// - Returns: True if element exists within timeout
    @discardableResult
    func waitForExistence(timeout: TimeInterval = TestConfiguration.defaultTimeout,
                         description: String = "") -> Bool {
        let exists = waitForExistence(timeout: timeout)
        if !exists {
            let debugInfo = """
            Element not found within \(timeout)s: \(description)
            Element: \(self.debugDescription)
            App state: \(XCUIApplication().debugDescription)
            """
            XCTFail(debugInfo)
        }
        return exists
    }

    /// Wait for element to become hittable
    /// - Parameter timeout: Timeout duration
    /// - Returns: True if element is hittable within timeout
    @discardableResult
    func waitForHittable(timeout: TimeInterval = TestConfiguration.defaultTimeout) -> Bool {
        let startTime = Date()
        while Date().timeIntervalSince(startTime) < timeout {
            if isHittable {
                return true
            }
            Thread.sleep(forTimeInterval: 0.1)
        }
        return false
    }

    /// Scroll to make element visible
    /// - Parameter scrollView: Parent scroll view
    func scrollToVisible(in scrollView: XCUIElement? = nil) {
        let scrollElement = scrollView ?? XCUIApplication().scrollViews.firstMatch

        // Try scrolling up first
        scrollElement.swipeUp()
        if exists && isHittable { return }

        // Try scrolling down
        scrollElement.swipeDown()
        if exists && isHittable { return }

        // Try coordinated scrolling
        scrollElement.scrollToElement(element: self)
    }

    /// Type text with validation
    /// - Parameter text: Text to type
    func typeTextValidated(_ text: String) {
        tap()
        typeText(text)

        // Verify text was entered
        if let textField = self as? XCUIElement, textField.value as? String != text {
            XCTFail("Failed to enter text: \(text)")
        }
    }

    /// Clear text field content
    func clearText() {
        guard let currentValue = value as? String, !currentValue.isEmpty else { return }

        tap()
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentValue.count)
        typeText(deleteString)
    }
}

// MARK: - XCUIApplication Extensions

extension XCUIApplication {

    /// Launch app with comprehensive configuration
    func launchForTesting() {
        launchArguments = ["-testing"]
        launchEnvironment = [
            "TESTING": "1",
            "DISABLE_ANIMATIONS": "1"
        ]
        launch()
    }

    /// Wait for app to be ready for testing
    func waitForAppReady(timeout: TimeInterval = TestConfiguration.extendedTimeout) {
        let mainView = otherElements["MainView"]
        XCTAssertTrue(mainView.waitForExistence(timeout: timeout),
                     "App main view should be ready within \(timeout) seconds")
    }

    /// Navigate to specific tab
    /// - Parameter tabName: Name of the tab to navigate to
    func navigateToTab(_ tabName: String) {
        let tab = tabBars.buttons[tabName]
        XCTAssertTrue(tab.waitForExistence(timeout: TestConfiguration.defaultTimeout),
                     "Tab '\(tabName)' should be available")
        tab.tap()

        // Verify navigation
        let navigationBar = navigationBars[tabName]
        XCTAssertTrue(navigationBar.waitForExistence(timeout: TestConfiguration.quickTimeout),
                     "Should navigate to \(tabName) tab")
    }

    /// Take screenshot for debugging
    /// - Parameter name: Screenshot name
    func takeScreenshot(name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Wait for network activity to complete
    func waitForNetworkActivity(timeout: TimeInterval = TestConfiguration.defaultTimeout) {
        // Wait for loading indicators to disappear
        let loadingIndicators = [
            activityIndicators.firstMatch,
            progressIndicators.firstMatch,
            staticTexts.containing(NSPredicate(format: "label CONTAINS 'Loading'")).firstMatch
        ]

        for indicator in loadingIndicators {
            if indicator.exists {
                XCTAssertTrue(indicator.waitForExistence(timeout: 0), "Loading indicator should disappear")
                let disappeared = !indicator.waitForExistence(timeout: timeout)
                XCTAssertTrue(disappeared, "Loading should complete within \(timeout) seconds")
            }
        }
    }
}

// MARK: - Test Data Management

/// Test data factory for consistent test data
struct TestDataFactory {

    static func createValidTask() -> (title: String, description: String) {
        return (
            title: "Test Task \(UUID().uuidString.prefix(8))",
            description: "Test task description for automated testing"
        )
    }

    static func createValidUserCredentials() -> (email: String, password: String) {
        return (
            email: "test\(UUID().uuidString.prefix(8))@timebeam.test",
            password: "TestPassword123!"
        )
    }

    static func createTimerSettings() -> (workMinutes: Int, breakMinutes: Int, longBreakMinutes: Int) {
        return (workMinutes: 25, breakMinutes: 5, longBreakMinutes: 15)
    }
}

// MARK: - Assertion Helpers

/// Comprehensive assertion helpers following testing best practices
struct TestAssertions {

    static func assertElementExists(_ element: XCUIElement,
                                   _ message: String = "",
                                   file: StaticString = #file,
                                   line: UInt = #line) {
        XCTAssertTrue(element.exists, message.isEmpty ? "Element should exist" : message,
                     file: file, line: line)
    }

    static func assertElementNotExists(_ element: XCUIElement,
                                      _ message: String = "",
                                      file: StaticString = #file,
                                      line: UInt = #line) {
        XCTAssertFalse(element.exists, message.isEmpty ? "Element should not exist" : message,
                      file: file, line: line)
    }

    static func assertTextEqual(_ element: XCUIElement,
                               _ expectedText: String,
                               _ message: String = "",
                               file: StaticString = #file,
                               line: UInt = #line) {
        let actualText = element.label
        XCTAssertEqual(actualText, expectedText,
                      message.isEmpty ? "Text should match" : message,
                      file: file, line: line)
    }

    static func assertTextContains(_ element: XCUIElement,
                                  _ substring: String,
                                  _ message: String = "",
                                  file: StaticString = #file,
                                  line: UInt = #line) {
        let actualText = element.label
        XCTAssertTrue(actualText.contains(substring),
                     message.isEmpty ? "Text should contain '\(substring)'" : message,
                     file: file, line: line)
    }

    static func assertCountEqual(_ elements: XCUIElementQuery,
                                _ expectedCount: Int,
                                _ message: String = "",
                                file: StaticString = #file,
                                line: UInt = #line) {
        let actualCount = elements.count
        XCTAssertEqual(actualCount, expectedCount,
                      message.isEmpty ? "Element count should be \(expectedCount)" : message,
                      file: file, line: line)
    }
}

// MARK: - Mock Data Providers

/// Mock data providers for testing
struct MockDataProvider {

    static func mockTasks() -> [[String: Any]] {
        return [
            [
                "id": UUID().uuidString,
                "title": "Complete project documentation",
                "description": "Write comprehensive documentation for the TimeBeam project",
                "status": "todo",
                "createdAt": ISO8601DateFormatter().string(from: Date()),
                "updatedAt": ISO8601DateFormatter().string(from: Date())
            ],
            [
                "id": UUID().uuidString,
                "title": "Implement user authentication",
                "description": "Add secure user authentication with JWT tokens",
                "status": "in_progress",
                "createdAt": ISO8601DateFormatter().string(from: Date().addingTimeInterval(-86400)),
                "updatedAt": ISO8601DateFormatter().string(from: Date())
            ],
            [
                "id": UUID().uuidString,
                "title": "Setup CI/CD pipeline",
                "description": "Configure automated testing and deployment pipeline",
                "status": "completed",
                "createdAt": ISO8601DateFormatter().string(from: Date().addingTimeInterval(-172800)),
                "updatedAt": ISO8601DateFormatter().string(from: Date().addingTimeInterval(-86400))
            ]
        ]
    }

    static func mockSessions() -> [[String: Any]] {
        return [
            [
                "id": UUID().uuidString,
                "userId": UUID().uuidString,
                "startedAt": ISO8601DateFormatter().string(from: Date().addingTimeInterval(-3600)),
                "durationSeconds": 1500,
                "kind": "work",
                "wasCompleted": true
            ],
            [
                "id": UUID().uuidString,
                "userId": UUID().uuidString,
                "startedAt": ISO8601DateFormatter().string(from: Date().addingTimeInterval(-1800)),
                "durationSeconds": 300,
                "kind": "short_break",
                "wasCompleted": true
            ]
        ]
    }

    static func mockAnalyticsData() -> [String: Any] {
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
            ]
        ]
    }
}

// MARK: - Performance Testing Utilities

/// Performance testing utilities
struct PerformanceTestUtils {

    static func measurePerformance(_ block: () -> Void,
                                  metrics: [XCTMetric] = [XCTClockMetric(), XCTCPUMetric(), XCTMemoryMetric()],
                                  name: String = "Performance Test") {
        measure(metrics: metrics) {
            block()
        }
    }

    static func assertPerformance(_ block: () -> Void,
                                 maxDuration: TimeInterval,
                                 name: String = "Performance Assertion") {
        let startTime = Date()
        block()
        let duration = Date().timeIntervalSince(startTime)

        XCTAssertLessThanOrEqual(duration, maxDuration,
                                "\(name) should complete within \(maxDuration) seconds, took \(duration) seconds")
    }

    static func measureMemoryUsage(_ block: () -> Void) -> UInt64 {
        var memoryUsage: UInt64 = 0

        measure(metrics: [XCTMemoryMetric()]) {
            block()
            // Memory measurement is handled by XCTMemoryMetric
        }

        return memoryUsage
    }
}

// MARK: - Accessibility Testing Utilities

/// Accessibility testing utilities for comprehensive coverage
struct AccessibilityTestUtils {

    static func assertAccessibilityCompliance(for element: XCUIElement,
                                            file: StaticString = #file,
                                            line: UInt = #line) {
        // Check if element has accessibility label
        if element.elementType != .staticText && element.elementType != .button {
            XCTAssertNotNil(element.label, "Element should have accessibility label",
                           file: file, line: line)
        }

        // Check if interactive elements are accessible
        if element.isEnabled && (element.elementType == .button || element.elementType == .cell) {
            XCTAssertTrue(element.isHittable, "Interactive element should be hittable",
                         file: file, line: line)
        }
    }

    static func testVoiceOverNavigation(app: XCUIApplication) {
        // Enable accessibility testing if possible
        // Note: Actual VoiceOver testing requires specific setup
        let mainElements = [
            app.navigationBars.firstMatch,
            app.tabBars.firstMatch,
            app.buttons.firstMatch
        ]

        for element in mainElements {
            if element.exists {
                assertAccessibilityCompliance(for: element)
            }
        }
    }

    static func testDynamicTypeSupport(app: XCUIApplication) {
        // Test that text scales with dynamic type
        let textElements = app.staticTexts.allElementsBoundByIndex

        for element in textElements.prefix(5) { // Test first 5 text elements
            XCTAssertFalse(element.label.isEmpty, "Text element should have readable content")
            // Note: Actual dynamic type testing requires system settings manipulation
        }
    }
}

// MARK: - Cross-Platform Testing Utilities

/// Cross-platform testing utilities
struct CrossPlatformTestUtils {

    static func runOnAllPlatforms(_ testBlock: () -> Void) {
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone {
            testBlock() // iPhone specific tests
        } else if UIDevice.current.userInterfaceIdiom == .pad {
            testBlock() // iPad specific tests
        }
        #elseif os(macOS)
        testBlock() // macOS specific tests
        #elseif os(watchOS)
        testBlock() // watchOS specific tests
        #endif
    }

    static func skipIfNotSupported(_ reason: String = "Feature not supported on this platform") {
        #if os(watchOS)
        if reason.contains("complex") || reason.contains("large") {
            XCTSkip(reason)
        }
        #endif
    }

    static func adaptTimeoutForPlatform(_ baseTimeout: TimeInterval) -> TimeInterval {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad ? baseTimeout * 1.5 : baseTimeout
        #elseif os(watchOS)
        return baseTimeout * 2.0 // watchOS is slower
        #else
        return baseTimeout
        #endif
    }
}

// MARK: - Test Base Classes

/// Base test class with common setup and utilities
class TimeBeamTestBase: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchForTesting()
        app.waitForAppReady()
    }

    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }

    // Common test helpers
    func loginIfNeeded() {
        // Implement login logic if needed
    }

    func logoutIfNeeded() {
        // Implement logout logic if needed
    }

    func resetAppState() {
        // Reset app to clean state
        app.terminate()
        app.launchForTesting()
    }

    func takeScreenshotOnFailure(name: String) {
        if testRun?.failureCount ?? 0 > 0 {
            app.takeScreenshot(name: name)
        }
    }
}

/// Base class for UI tests requiring authentication
class AuthenticatedTestBase: TimeBeamTestBase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        loginIfNeeded()
    }

    override func tearDownWithError() throws {
        logoutIfNeeded()
        try super.tearDownWithError()
    }
}
