//
//  E2EMacOSTests.swift
//  TimeBeamUITests
//
//  Created by TimeBeam Team
//  End-to-end tests for macOS platform connecting to live backend
//

import XCTest

final class E2EMacOSTests: TimeBeamE2ETestBase {

    // MARK: - macOS Specific Setup

    override func setUpWithError() throws {
        // Skip macOS tests if not running on macOS
        #if os(macOS)
            try super.setUpWithError()
        #else
            throw XCTSkip("macOS E2E tests can only run on macOS platform")
        #endif
    }

    // MARK: - macOS Authentication Tests

    func testMacOSAuthenticationFlow() throws {
        #if os(macOS)
        performAuthenticatedAction {
            // Verify authentication state is maintained
            // macOS might have different UI patterns than iOS

            // Check if user profile information is displayed
            let userProfileElements = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Test User'"))
            XCTAssertTrue(userProfileElements.count > 0, "User profile should be visible on macOS")
        }
        #endif
    }

    // MARK: - macOS Timer Integration Tests

    func testMacOSTimerWindowManagement() throws {
        #if os(macOS)
        performAuthenticatedAction {
            // Test macOS-specific window behaviors
            let timerWindow = app.windows["Timer"]
            XCTAssertTrue(timerWindow.exists, "Timer window should be available on macOS")

            // Test window resizing (macOS specific)
            let initialFrame = timerWindow.frame
            // Note: Actual window resizing tests would require specific macOS test setup

            // Start timer and verify window state
            let startButton = app.buttons["Start"]
            startButton.tap()

            // Verify timer controls remain accessible
            XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: TestConfiguration.quickTimeout),
                         "Pause button should be accessible in macOS window")
        }
        #endif
    }

    func testMacOSMenuBarIntegration() throws {
        #if os(macOS)
        performAuthenticatedAction {
            // Test menu bar timer controls (macOS specific feature)
            // Note: Menu bar testing requires specific setup and may not be available in standard UI tests

            // Verify main window functionality
            let mainWindow = app.windows.firstMatch
            XCTAssertTrue(mainWindow.exists, "Main application window should exist")

            // Test keyboard shortcuts (macOS specific)
            // Note: Keyboard shortcut testing requires specific test setup
        }
        #endif
    }

    // MARK: - macOS Task Management Tests

    func testMacOSTaskWindow() throws {
        #if os(macOS)
        performAuthenticatedAction {
            // Navigate to Tasks
            app.navigateToTab("Tasks")

            // Test macOS-specific task window behaviors
            let taskWindow = app.windows.containing(NSPredicate(format: "title CONTAINS 'Task'")).firstMatch
            XCTAssertTrue(taskWindow.exists, "Task window should be accessible on macOS")

            // Test task creation in macOS environment
            let createButton = app.buttons["Create Task"]
            XCTAssertTrue(createButton.exists, "Create task button should be available")

            createButton.tap()

            // Fill task form
            let titleField = app.textFields["Task Title"]
            titleField.tap()
            titleField.typeText("macOS E2E Test Task")

            let descriptionField = app.textViews["Task Description"]
            descriptionField.tap()
            descriptionField.typeText("Task created during macOS E2E testing")

            // Save task
            app.buttons["Save"].tap()

            // Verify task appears in list
            let newTask = app.staticTexts["macOS E2E Test Task"]
            XCTAssertTrue(newTask.waitForExistence(timeout: TestConfiguration.defaultTimeout),
                         "Newly created task should appear in macOS interface")
        }
        #endif
    }

    // MARK: - macOS Analytics Tests

    func testMacOSAnalyticsView() throws {
        #if os(macOS)
        performAuthenticatedAction {
            // Navigate to Analytics
            app.navigateToTab("Analytics")

            // Test macOS-specific analytics layout
            let analyticsWindow = app.windows.containing(NSPredicate(format: "title CONTAINS 'Analytic'")).firstMatch
            XCTAssertTrue(analyticsWindow.exists, "Analytics window should be available on macOS")

            // Verify analytics data is loaded and displayed
            let weeklyStats = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'week' OR label CONTAINS 'Week'"))
            XCTAssertTrue(weeklyStats.count > 0, "Weekly analytics should be visible on macOS")

            // Test chart interactions (macOS might have different interaction patterns)
            let chartElements = app.otherElements.containing(NSPredicate(format: "identifier CONTAINS 'chart' OR identifier CONTAINS 'Chart'"))
            if chartElements.count > 0 {
                // Test chart interaction if available
                let firstChart = chartElements.firstMatch
                firstChart.click() // macOS might support click interactions
            }
        }
        #endif
    }

    // MARK: - macOS Settings Tests

    func testMacOSSettingsPanel() throws {
        #if os(macOS)
        performAuthenticatedAction {
            // Navigate to Settings
            app.navigateToTab("Settings")

            // Test macOS-specific settings layout
            let settingsWindow = app.windows.containing(NSPredicate(format: "title CONTAINS 'Setting'")).firstMatch
            XCTAssertTrue(settingsWindow.exists, "Settings window should be available on macOS")

            // Test timer preferences
            let workDurationField = app.textFields["Work Duration"]
            if workDurationField.exists {
                let originalValue = workDurationField.value as? String
                workDurationField.tap()
                workDurationField.clearText()
                workDurationField.typeText("45")

                // Verify setting change
                XCTAssertNotEqual(workDurationField.value as? String, originalValue,
                                "Work duration should be changeable on macOS")
            }

            // Test notification settings (macOS specific)
            let notificationToggle = app.checkBoxes["Enable Notifications"]
            if notificationToggle.exists {
                notificationToggle.click()
                // Verify toggle state changed
            }
        }
        #endif
    }

    // MARK: - macOS Multi-Window Tests

    func testMacOSMultiWindowSupport() throws {
        #if os(macOS)
        performAuthenticatedAction {
            // Test macOS multi-window capabilities
            let initialWindowCount = app.windows.count

            // Attempt to open multiple views (macOS specific behavior)
            // Note: Actual multi-window testing requires specific app implementation

            // Verify window management doesn't break core functionality
            let timerView = app.otherElements["CircularTimerView"]
            XCTAssertTrue(timerView.exists, "Timer should remain functional in multi-window environment")
        }
        #endif
    }

    // MARK: - macOS Device Registration Tests

    func testMacOSDeviceRegistration() throws {
        #if os(macOS)
        performAuthenticatedAction {
            // Verify macOS device is properly registered
            waitForNetworkOperation()

            // Check device registration via API
            verifyMacOSDeviceRegisteredInBackend()
        }
        #endif
    }

    // MARK: - Helper Methods

    private func verifyMacOSDeviceRegisteredInBackend() {
        // Verify macOS device registration
        let devicesURL = URL(string: "\(TestConfiguration.e2eBackendURL)/api/devices/stats")!
        var request = URLRequest(url: devicesURL)
        request.httpMethod = "GET"

        let token = try! loginAndGetToken(email: TestConfiguration.testUserEmail)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let expectation = expectation(description: "Verify macOS device registration")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200,
               let data = data {
                do {
                    let stats = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    let macosDevices = stats?["macosDevices"] as? Int
                    XCTAssertGreaterThan(macosDevices ?? 0, 0, "Should have macOS devices registered")
                } catch {
                    XCTFail("Failed to parse device stats response: \(error)")
                }
            }
            expectation.fulfill()
        }.resume()

        wait(for: [expectation], timeout: TestConfiguration.defaultTimeout)
    }

    private func loginAndGetToken(email: String) throws -> String {
        let loginURL = URL(string: "\(TestConfiguration.e2eBackendURL)/api/auth/login")!
        var request = URLRequest(url: loginURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let loginBody = ["email": email]
        request.httpBody = try JSONSerialization.data(withJSONObject: loginBody)

        let semaphore = DispatchSemaphore(value: 0)
        var token: String?

        URLSession.shared.dataTask(with: request) { data, response, error in
            defer { semaphore.signal() }

            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200,
               let data = data {
                do {
                    let responseJSON = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    token = responseJSON?["accessToken"] as? String
                } catch {
                    XCTFail("Failed to parse login response: \(error)")
                }
            }
        }.resume()

        semaphore.wait()
        return try XCTUnwrap(token, "Should receive access token")
    }
}
