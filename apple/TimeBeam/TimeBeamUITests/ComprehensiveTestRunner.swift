import XCTest

final class ComprehensiveTestRunner: XCTestCase {

    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    override func tearDownWithError() throws {
        // Clean up after each test
    }

    // MARK: - Comprehensive Test Suites

    func testCompleteAppWorkflow() throws {
        // Test the complete user workflow across all app features

        // 1. Test Timer functionality
        testTimerWorkflow()

        // 2. Test Task Management functionality
        testTaskWorkflow()

        // 3. Test Timer-Task Integration
        testTimerTaskIntegrationWorkflow()

        // 4. Test Analytics functionality
        testAnalyticsWorkflow()

        // 5. Test Settings functionality
        testSettingsWorkflow()

        // 6. Test Navigation
        testNavigationWorkflow()
    }

    private func testTimerWorkflow() throws {
        // Test timer start/pause/reset functionality
        TestUtilities.startTimer(app)
        TestUtilities.pauseTimer(app)
        TestUtilities.resetTimer(app)

        // Verify timer is in correct state
        let startButton = app.buttons["Start"]
        XCTAssertTrue(startButton.exists, "Timer should be reset to start state")
    }

    private func testTaskWorkflow() throws {
        // Test basic task management functionality
        TestUtilities.navigateToTasks(app)

        // Test task creation
        let createTaskButton = app.buttons["Create Task"]
        if createTaskButton.waitForExistence(timeout: 5) {
            createTaskButton.tap()

            // Fill out task form
            let titleField = app.textFields["Task Title"]
            if titleField.waitForExistence(timeout: 2) {
                titleField.tap()
                titleField.typeText("Test Task")

                let saveButton = app.buttons["Save"]
                saveButton.tap()

                // Verify task was created
                let taskCell = app.cells.staticTexts["Test Task"]
                XCTAssertTrue(taskCell.waitForExistence(timeout: 5), "Task should be created and visible")
            }
        }

        // Return to timer
        TestUtilities.navigateToTimer(app)
    }

    private func testTimerTaskIntegrationWorkflow() throws {
        // Test timer-task integration
        let selectTaskButton = app.buttons["Select Task"]
        if selectTaskButton.waitForExistence(timeout: 5) {
            selectTaskButton.tap()

            // Select first available task
            let taskOption = app.buttons.element(boundBy: 0)
            if taskOption.waitForExistence(timeout: 2) {
                taskOption.tap()

                // Verify task is selected
                let currentTaskDisplay = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Working on'")).firstMatch
                XCTAssertTrue(currentTaskDisplay.exists, "Task should be selected in timer")

                // Start timer with task
                TestUtilities.startTimer(app)

                // Verify task context is maintained
                XCTAssertTrue(currentTaskDisplay.exists, "Task context should persist during timer operation")

                // Stop timer
                TestUtilities.pauseTimer(app)
            }
        }
    }

    private func testAnalyticsWorkflow() throws {
        // Navigate to analytics
        TestUtilities.navigateToAnalytics(app)

        // Wait for data to load
        let headerCard = app.staticTexts["Weekly?"]
        XCTAssertTrue(headerCard.waitForExistence(timeout: 10), "Analytics should load")

        // Test scrolling
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeUp()
            scrollView.swipeDown()
        }

        // Return to timer
        TestUtilities.navigateToTimer(app)
    }

    private func testSettingsWorkflow() throws {
        // Navigate to settings
        TestUtilities.navigateToSettings(app)

        // Test settings UI elements
        let settingsHeader = app.staticTexts["Settings"]
        XCTAssertTrue(settingsHeader.exists, "Settings should be visible")

        // Return to timer
        TestUtilities.navigateToTimer(app)
    }

    private func testNavigationWorkflow() throws {
        // Test navigation between all tabs
        for _ in 0..<3 {
            TestUtilities.navigateToAnalytics(app)
            TestUtilities.navigateToSettings(app)
            TestUtilities.navigateToTimer(app)
        }
    }

    // MARK: - Cross-Platform Test Suite

    func testCrossPlatformFunctionality() throws {
        // Test functionality that should work across all platforms

        // Test timer controls
        testTimerControls()

        // Test navigation
        testCrossPlatformNavigation()

        // Test accessibility
        testCrossPlatformAccessibility()
    }

    private func testTimerControls() throws {
        // Test basic timer controls work on all platforms
        TestUtilities.startTimer(app)
        TestUtilities.pauseTimer(app)
        TestUtilities.resetTimer(app)
    }

    private func testCrossPlatformNavigation() throws {
        // Test navigation works on all platforms
        TestUtilities.navigateToAnalytics(app)
        TestUtilities.navigateToTimer(app)
        TestUtilities.navigateToSettings(app)
        TestUtilities.navigateToTimer(app)
    }

    private func testCrossPlatformAccessibility() throws {
        // Test accessibility features work on all platforms
        let startButton = app.buttons["Start"]
        TestUtilities.testAccessibilityForElement(startButton, elementName: "Start button")

        let resetButton = app.buttons["Reset"]
        TestUtilities.testAccessibilityForElement(resetButton, elementName: "Reset button")
    }

    // MARK: - Platform-Specific Test Suite

    func testPlatformSpecificFeatures() throws {
        if TestUtilities.isRunningOnMacOS() {
            testMacOSSpecificFeatures()
        } else if TestUtilities.isRunningOnWatchOS() {
            testWatchOSSpecificFeatures()
        } else {
            testIOSSpecificFeatures()
        }
    }

    private func testIOSSpecificFeatures() throws {
        // Test iOS-specific features like tab bar
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "Tab bar should exist on iOS")

        // Test all tabs
        let timerTab = app.tabBars.buttons["Timer"]
        let analyticsTab = app.tabBars.buttons["Analytics"]
        let settingsTab = app.tabBars.buttons["Settings"]

        XCTAssertTrue(timerTab.exists, "Timer tab should exist")
        XCTAssertTrue(analyticsTab.exists, "Analytics tab should exist")
        XCTAssertTrue(settingsTab.exists, "Settings tab should exist")
    }

    private func testMacOSSpecificFeatures() throws {
        // Test macOS-specific features like menu options
        let optionsButton = app.buttons["Options"]
        XCTAssertTrue(optionsButton.exists, "Options button should exist on macOS")

        // Test options menu
        optionsButton.click()

        // Check for macOS-specific menu items
        let analyticsButton = app.buttons["Analytics & Insights…"]
        XCTAssertTrue(analyticsButton.exists, "Analytics button should exist in macOS menu")

        // Close menu
        optionsButton.click()
    }

    private func testWatchOSSpecificFeatures() throws {
        // Test watchOS-specific features like compact layout
        let timerRing = app.otherElements["CircularTimerView"]
        let ringSize = timerRing.frame.size

        // Verify compact layout for watch
        XCTAssertTrue(ringSize.width <= 150, "Timer ring should be compact on watchOS")
        XCTAssertTrue(ringSize.height <= 150, "Timer ring should be compact on watchOS")

        // Test that UI is appropriately sized for small screen
        let startButton = app.buttons["Start"]
        let buttonSize = startButton.frame.size
        XCTAssertTrue(buttonSize.width <= 60, "Button should be compact on watchOS")
        XCTAssertTrue(buttonSize.height <= 60, "Button should be compact on watchOS")
    }

    // MARK: - Performance Test Suite

    func testPerformanceAcrossAllFeatures() throws {
        // Test performance of all major features

        // Test timer performance
        measureTimerPerformance()

        // Test navigation performance
        measureNavigationPerformance()

        // Test analytics performance
        measureAnalyticsPerformance()
    }

    private func measureTimerPerformance() throws {
        measure(metrics: [XCTClockMetric(), XCTCPUMetric()]) {
            for _ in 0..<5 {
                TestUtilities.startTimer(app)
                TestUtilities.pauseTimer(app)
            }
        }
    }

    private func measureNavigationPerformance() throws {
        measure(metrics: [XCTClockMetric(), XCTCPUMetric()]) {
            for _ in 0..<3 {
                TestUtilities.navigateToAnalytics(app)
                TestUtilities.navigateToSettings(app)
                TestUtilities.navigateToTimer(app)
            }
        }
    }

    private func measureAnalyticsPerformance() throws {
        measure(metrics: [XCTClockMetric(), XCTCPUMetric(), XCTMemoryMetric()]) {
            TestUtilities.navigateToAnalytics(app)

            // Wait for data to load
            let headerCard = app.staticTexts["Weekly?"]
            XCTAssertTrue(headerCard.waitForExistence(timeout: 10), "Analytics should load")

            // Scroll through content
            let scrollView = app.scrollViews.firstMatch
            if scrollView.exists {
                scrollView.swipeUp()
                scrollView.swipeDown()
            }

            // Return to timer
            TestUtilities.navigateToTimer(app)
        }
    }

    // MARK: - Error Handling Test Suite

    func testErrorHandlingAndRecovery() throws {
        // Test error handling across the app

        // Test analytics error handling
        testAnalyticsErrorHandling()

        // Test timer error recovery
        testTimerErrorRecovery()
    }

    private func testAnalyticsErrorHandling() throws {
        TestUtilities.navigateToAnalytics(app)

        // If error occurs, test recovery
        let errorTitle = app.staticTexts["Unable to Load Analytics"]
        if errorTitle.exists {
            let tryAgainButton = app.buttons["Try Again"]
            if tryAgainButton.exists {
                tryAgainButton.tap()
                // Wait for recovery
                let headerCard = app.staticTexts["Weekly?"]
                XCTAssertTrue(headerCard.waitForExistence(timeout: 10), "Should recover from error")
            }
        }

        // Return to timer
        TestUtilities.navigateToTimer(app)
    }

    private func testTimerErrorRecovery() throws {
        // Test timer error recovery by resetting
        TestUtilities.startTimer(app)
        TestUtilities.resetTimer(app)

        // Verify timer is in correct state
        let startButton = app.buttons["Start"]
        XCTAssertTrue(startButton.exists, "Timer should be reset to start state")
    }

    // MARK: - Helper Methods

    private func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        return element.waitForExistence(timeout: timeout)
    }

    private func assertElementExists(_ element: XCUIElement, _ message: String = "") {
        XCTAssertTrue(element.exists, message.isEmpty ? "Element should exist" : message)
    }
}
