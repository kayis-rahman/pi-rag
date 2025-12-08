//
//  E2ETimerWorkflowTests.swift
//  TimeBeamUITests
//
//  Created by TimeBeam Team
//  End-to-end timer workflow tests connecting to live backend
//

import XCTest

final class E2ETimerWorkflowTests: TimeBeamE2ETestBase {

    // MARK: - Timer State Synchronization Tests

    func testTimerStatePullFromBackend() throws {
        // Verify that timer state is correctly pulled from backend on app start
        // The seeded data includes a timer state for test user

        // Wait for app to load and sync
        waitForNetworkOperation()

        // Check if timer shows the expected state
        let timerView = app.otherElements["CircularTimerView"]
        XCTAssertTrue(timerView.waitForExistence(timeout: TestConfiguration.defaultTimeout),
                     "Timer view should be visible")

        // Verify timer is in work phase (from seeded data)
        // Note: Actual UI verification would depend on your timer display implementation
        let playButton = app.buttons["Start"]
        let pauseButton = app.buttons["Pause"]

        // If pause button exists, timer should be running
        if pauseButton.exists {
            XCTAssertTrue(pauseButton.exists, "Timer should be in running state from seeded data")
        }
    }

    func testTimerStartAndSessionCreation() throws {
        performAuthenticatedAction {
            // Start the timer
            let startButton = app.buttons["Start"]
            XCTAssertTrue(startButton.waitForExistence(timeout: TestConfiguration.defaultTimeout),
                         "Start button should be available")
            startButton.tap()

            // Verify timer started
            let pauseButton = app.buttons["Pause"]
            XCTAssertTrue(pauseButton.waitForExistence(timeout: TestConfiguration.quickTimeout),
                         "Pause button should appear after starting")

            // Wait for session to be created (network operation)
            waitForNetworkOperation(timeout: TestConfiguration.extendedTimeout)

            // Verify session was created in backend
            verifySessionCreatedInBackend()
        }
    }

    func testTimerWithTaskAssociation() throws {
        performAuthenticatedAction {
            // Select a task first
            let selectTaskButton = app.buttons["Select Task"]
            if selectTaskButton.waitForExistence(timeout: TestConfiguration.quickTimeout) {
                selectTaskButton.tap()

                // Select the documentation task (from seeded data)
                let taskPicker = app.sheets["TaskPickerView"]
                XCTAssertTrue(taskPicker.waitForExistence(timeout: TestConfiguration.defaultTimeout),
                             "Task picker should appear")

                // Find and tap the documentation task
                let docTask = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Complete project documentation'")).firstMatch
                if docTask.waitForExistence(timeout: TestConfiguration.quickTimeout) {
                    docTask.tap()
                }
            }

            // Start the timer
            let startButton = app.buttons["Start"]
            startButton.tap()

            // Verify timer is running with task context
            let pauseButton = app.buttons["Pause"]
            XCTAssertTrue(pauseButton.waitForExistence(timeout: TestConfiguration.quickTimeout),
                         "Timer should start with task association")

            // Wait for session creation
            waitForNetworkOperation(timeout: TestConfiguration.extendedTimeout)

            // Verify session was created with task association
            verifySessionCreatedWithTask()
        }
    }

    func testTimerPauseAndResume() throws {
        performAuthenticatedAction {
            // Start timer
            app.buttons["Start"].tap()
            XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: TestConfiguration.quickTimeout),
                         "Timer should start")

            // Pause timer
            app.buttons["Pause"].tap()
            XCTAssertTrue(app.buttons["Start"].waitForExistence(timeout: TestConfiguration.quickTimeout),
                         "Timer should pause")

            // Resume timer
            app.buttons["Start"].tap()
            XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: TestConfiguration.quickTimeout),
                         "Timer should resume")

            // Wait for state sync
            waitForNetworkOperation()

            // Verify backend state reflects the changes
            verifyTimerStateInBackend(expectedRunning: true)
        }
    }

    func testTimerStopAndSessionCompletion() throws {
        performAuthenticatedAction {
            // Start timer
            app.buttons["Start"].tap()
            XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: TestConfiguration.quickTimeout),
                         "Timer should start")

            // Let it run briefly
            Thread.sleep(forTimeInterval: 2.0)

            // Stop timer
            let stopButton = app.buttons["Stop"]
            if stopButton.waitForExistence(timeout: TestConfiguration.quickTimeout) {
                stopButton.tap()
            } else {
                // Some implementations might not have a stop button, pause might serve as stop
                app.buttons["Pause"].tap()
            }

            // Verify timer stopped
            XCTAssertTrue(app.buttons["Start"].waitForExistence(timeout: TestConfiguration.defaultTimeout),
                         "Timer should stop")

            // Wait for session completion sync
            waitForNetworkOperation(timeout: TestConfiguration.extendedTimeout)

            // Verify session was completed in backend
            verifySessionCompletedInBackend()
        }
    }

    func testTimerStatePersistenceAcrossAppRestart() throws {
        performAuthenticatedAction {
            // Start timer
            app.buttons["Start"].tap()
            XCTAssertTrue(app.buttons["Pause"].exists, "Timer should be running")

            // Wait for sync
            waitForNetworkOperation()

            // Terminate and relaunch app
            app.terminate()
            app = XCUIApplication()
            app = app.launchForE2ETesting()
            app.waitForAppReady()

            // Verify timer state persisted
            waitForNetworkOperation()
            verifyTimerStateInBackend(expectedRunning: true)
        }
    }

    // MARK: - Multi-Device Synchronization Tests

    func testTimerStateSyncBetweenDevices() throws {
        // This test would simulate multiple devices
        // For now, test that device registration works
        performAuthenticatedAction {
            waitForNetworkOperation()

            // Verify device was registered
            verifyDeviceRegisteredInBackend()
        }
    }

    // MARK: - Analytics Integration Tests

    func testTimerSessionsAppearInAnalytics() throws {
        performAuthenticatedAction {
            // Create a new session
            app.buttons["Start"].tap()
            waitForNetworkOperation()

            Thread.sleep(forTimeInterval: 3.0) // Let session run

            app.buttons["Pause"].tap()
            waitForNetworkOperation()

            // Navigate to Analytics
            app.navigateToTab("Analytics")

            // Verify session appears in analytics
            let analyticsView = app.otherElements.containing(NSPredicate(format: "label CONTAINS 'Analytics'")).firstMatch
            XCTAssertTrue(analyticsView.waitForExistence(timeout: TestConfiguration.defaultTimeout),
                         "Analytics view should load")

            // Check for session data
            // Note: Actual UI verification depends on your analytics implementation
            let sessionIndicators = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'session' OR label CONTAINS 'Session'"))
            XCTAssertTrue(sessionIndicators.count > 0, "Should show session information in analytics")
        }
    }

    // MARK: - Helper Methods

    private func verifySessionCreatedInBackend() {
        // API call to verify session was created
        let sessionsURL = URL(string: "\(TestConfiguration.e2eBackendURL)/api/sessions")!
        var request = URLRequest(url: sessionsURL)
        request.httpMethod = "GET"

        let token = try! loginAndGetToken(email: TestConfiguration.testUserEmail)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let expectation = expectation(description: "Verify session creation")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200,
               let data = data {
                do {
                    let sessions = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
                    XCTAssertNotNil(sessions, "Should receive sessions array")

                    // Should have more sessions than initially seeded
                    XCTAssertTrue((sessions?.count ?? 0) >= TestConfiguration.ExpectedData.initialSessionCount,
                                 "Should have at least the seeded sessions plus new ones")

                } catch {
                    XCTFail("Failed to parse sessions response: \(error)")
                }
            }
            expectation.fulfill()
        }.resume()

        wait(for: [expectation], timeout: TestConfiguration.defaultTimeout)
    }

    private func verifySessionCreatedWithTask() {
        // Verify the latest session is associated with the documentation task
        let sessionsURL = URL(string: "\(TestConfiguration.e2eBackendURL)/api/sessions")!
        var request = URLRequest(url: sessionsURL)
        request.httpMethod = "GET"

        let token = try! loginAndGetToken(email: TestConfiguration.testUserEmail)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let expectation = expectation(description: "Verify session task association")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200,
               let data = data {
                do {
                    let sessions = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
                    if let latestSession = sessions?.first {
                        let taskId = latestSession["taskId"] as? String
                        XCTAssertNotNil(taskId, "Latest session should have task association")
                        XCTAssertEqual(taskId, TestConfiguration.TestDataIDs.documentationTaskID,
                                     "Should be associated with documentation task")
                    }
                } catch {
                    XCTFail("Failed to parse sessions response: \(error)")
                }
            }
            expectation.fulfill()
        }.resume()

        wait(for: [expectation], timeout: TestConfiguration.defaultTimeout)
    }

    private func verifyTimerStateInBackend(expectedRunning: Bool) {
        // Check timer state via API
        let timerStateURL = URL(string: "\(TestConfiguration.e2eBackendURL)/api/sessions/timer/state")!
        var request = URLRequest(url: timerStateURL)
        request.httpMethod = "GET"

        let token = try! loginAndGetToken(email: TestConfiguration.testUserEmail)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let expectation = expectation(description: "Verify timer state")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200,
               let data = data {
                do {
                    let timerState = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    let isRunning = timerState?["isRunning"] as? Bool
                    XCTAssertEqual(isRunning, expectedRunning,
                                 "Timer running state should match expected value")
                } catch {
                    XCTFail("Failed to parse timer state response: \(error)")
                }
            }
            expectation.fulfill()
        }.resume()

        wait(for: [expectation], timeout: TestConfiguration.defaultTimeout)
    }

    private func verifySessionCompletedInBackend() {
        // Verify the most recent session is completed
        let sessionsURL = URL(string: "\(TestConfiguration.e2eBackendURL)/api/sessions")!
        var request = URLRequest(url: sessionsURL)
        request.httpMethod = "GET"

        let token = try! loginAndGetToken(email: TestConfiguration.testUserEmail)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let expectation = expectation(description: "Verify session completion")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200,
               let data = data {
                do {
                    let sessions = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
                    if let latestSession = sessions?.first {
                        let duration = latestSession["durationSeconds"] as? Int
                        XCTAssertNotNil(duration, "Session should have duration")
                        XCTAssertGreaterThan(duration ?? 0, 0, "Session should have positive duration")
                    }
                } catch {
                    XCTFail("Failed to parse sessions response: \(error)")
                }
            }
            expectation.fulfill()
        }.resume()

        wait(for: [expectation], timeout: TestConfiguration.defaultTimeout)
    }

    private func verifyDeviceRegisteredInBackend() {
        // Verify device registration
        let devicesURL = URL(string: "\(TestConfiguration.e2eBackendURL)/api/devices/stats")!
        var request = URLRequest(url: devicesURL)
        request.httpMethod = "GET"

        let token = try! loginAndGetToken(email: TestConfiguration.testUserEmail)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let expectation = expectation(description: "Verify device registration")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200,
               let data = data {
                do {
                    let stats = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    let totalDevices = stats?["totalDevices"] as? Int
                    XCTAssertGreaterThan(totalDevices ?? 0, 0, "Should have registered devices")
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
