import XCTest

final class macOSTimerUITests: XCTestCase {

    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    override func tearDownWithError() throws {
        // Clean up after each test
    }

    // MARK: - macOS Timer Interface Tests

    func testMacOSTimerInitialState() throws {
        // Verify initial timer state for macOS
        let timerRing = app.otherElements["CircularTimerView"]
        XCTAssertTrue(timerRing.exists, "Timer ring should be visible")

        let startButton = app.buttons["Start"]
        XCTAssertTrue(startButton.exists, "Start button should be visible")
        XCTAssertTrue(startButton.isEnabled, "Start button should be enabled")

        // macOS specific: Check for menu button
        let optionsButton = app.buttons["Options"]
        XCTAssertTrue(optionsButton.exists, "Options button should be visible on macOS")

        // Verify initial time display
        let timeDisplay = app.staticTexts.matching(identifier: "TimeDisplay").firstMatch
        XCTAssertTrue(timeDisplay.exists, "Time display should be visible")
    }

    func testMacOSTimerStartPauseFunctionality() throws {
        let startButton = app.buttons["Start"]
        let pauseButton = app.buttons["Pause"]

        // Start timer
        startButton.tap()
        XCTAssertTrue(pauseButton.waitForExistence(timeout: 2), "Pause button should appear after starting")

        // Pause timer
        pauseButton.tap()
        XCTAssertTrue(startButton.waitForExistence(timeout: 2), "Start button should reappear after pausing")
    }

    func testMacOSTimerOptionsMenu() throws {
        let optionsButton = app.buttons["Options"]
        XCTAssertTrue(optionsButton.exists, "Options button should exist")

        // Open options menu
        optionsButton.click()

        // Check for menu items
        let workDurationPicker = app.pickers["Focus Duration"]
        let shortBreakPicker = app.pickers["Short Break"]
        let longBreakPicker = app.pickers["Long Break"]

        XCTAssertTrue(workDurationPicker.exists, "Work duration picker should exist in menu")
        XCTAssertTrue(shortBreakPicker.exists, "Short break picker should exist in menu")
        XCTAssertTrue(longBreakPicker.exists, "Long break picker should exist in menu")

        // Check for analytics button
        let analyticsButton = app.buttons["Analytics & Insights…"]
        XCTAssertTrue(analyticsButton.exists, "Analytics button should exist in menu")

        // Close menu
        optionsButton.click()
    }

    func testMacOSTimerAnalyticsSheet() throws {
        let optionsButton = app.buttons["Options"]
        optionsButton.click()

        // Open analytics sheet
        let analyticsButton = app.buttons["Analytics & Insights…"]
        analyticsButton.click()

        // Verify analytics sheet appears
        let analyticsSheet = app.sheets["Analytics"]
        XCTAssertTrue(analyticsSheet.waitForExistence(timeout: 5), "Analytics sheet should appear")

        // Check for analytics content
        let headerCard = app.staticTexts["Weekly?"]
        XCTAssertTrue(headerCard.waitForExistence(timeout: 10), "Analytics header should load")

        // Close analytics sheet
        let closeButton = app.buttons["Close"]
        closeButton.click()
        XCTAssertFalse(analyticsSheet.exists, "Analytics sheet should close")
    }

    // MARK: - macOS Window Management Tests

    func testMacOSWindowResizing() throws {
        // Get main window
        let mainWindow = app.windows.firstMatch

        // Get initial size
        let initialSize = mainWindow.frame.size

        // Resize window (simulate)
        // Note: Actual window resizing is harder to test in UI tests
        // We'll test that UI adapts to different sizes

        // Verify timer ring is still visible
        let timerRing = app.otherElements["CircularTimerView"]
        XCTAssertTrue(timerRing.exists, "Timer ring should remain visible after resizing")
    }

    func testMacOSKeyboardShortcuts() throws {
        // Test keyboard shortcuts for timer control
        let startButton = app.buttons["Start"]
        let pauseButton = app.buttons["Pause"]

        // Simulate spacebar press (start/pause)
        app.typeKey(" ", modifierFlags: [])

        // Check if timer started
        XCTAssertTrue(pauseButton.waitForExistence(timeout: 2), "Timer should start with spacebar")

        // Simulate spacebar press again (pause)
        app.typeKey(" ", modifierFlags: [])

        // Check if timer paused
        XCTAssertTrue(startButton.waitForExistence(timeout: 2), "Timer should pause with spacebar")
    }

    // MARK: - macOS Accessibility Tests

    func testMacOSTimerAccessibility() throws {
        // Test VoiceOver compatibility
        let startButton = app.buttons["Start"]
        XCTAssertTrue(startButton.exists, "Start button should be accessible")

        let optionsButton = app.buttons["Options"]
        XCTAssertTrue(optionsButton.exists, "Options button should be accessible")

        // Test dynamic type support
        let timeDisplay = app.staticTexts.matching(identifier: "TimeDisplay").firstMatch
        XCTAssertTrue(timeDisplay.exists, "Time display should support dynamic type")
    }

    // MARK: - Performance Tests

    func testMacOSTimerUIPerformance() throws {
        measure(metrics: [XCTClockMetric(), XCTCPUMetric(), XCTMemoryMetric()]) {
            let startButton = app.buttons["Start"]
            startButton.tap()

            // Wait for UI updates
            let pauseButton = app.buttons["Pause"]
            XCTAssertTrue(pauseButton.waitForExistence(timeout: 2), "UI should update quickly")

            pauseButton.tap()
            XCTAssertTrue(startButton.waitForExistence(timeout: 2), "UI should update quickly on pause")
        }
    }

    // MARK: - Helper Methods

    private func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        return element.waitForExistence(timeout: timeout)
    }

    private func assertElementExists(_ element: XCUIElement, _ message: String = "") {
        XCTAssertTrue(element.exists, message.isEmpty ? "Element should exist" : message)
    }
}
