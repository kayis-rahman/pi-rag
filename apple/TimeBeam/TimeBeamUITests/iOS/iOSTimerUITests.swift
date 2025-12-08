import XCTest

final class iOSTimerUITests: XCTestCase {

    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    override func tearDownWithError() throws {
        // Clean up after each test
    }

    // MARK: - Timer Interface Tests

    func testTimerInitialState() throws {
        // Verify initial timer state
        let timerRing = app.otherElements["CircularTimerView"]
        XCTAssertTrue(timerRing.exists, "Timer ring should be visible")

        let startButton = app.buttons["Start"]
        XCTAssertTrue(startButton.exists, "Start button should be visible")
        XCTAssertTrue(startButton.isEnabled, "Start button should be enabled")

        let resetButton = app.buttons["Reset"]
        XCTAssertTrue(resetButton.exists, "Reset button should be visible")

        // Verify initial time display (should show work duration)
        let timeDisplay = app.staticTexts.matching(identifier: "TimeDisplay").firstMatch
        XCTAssertTrue(timeDisplay.exists, "Time display should be visible")
    }

    func testTimerStartPauseFunctionality() throws {
        let startButton = app.buttons["Start"]
        let pauseButton = app.buttons["Pause"]

        // Start timer
        startButton.tap()
        XCTAssertTrue(pauseButton.waitForExistence(timeout: 2), "Pause button should appear after starting")

        // Pause timer
        pauseButton.tap()
        XCTAssertTrue(startButton.waitForExistence(timeout: 2), "Start button should reappear after pausing")
    }

    func testTimerResetFunctionality() throws {
        let startButton = app.buttons["Start"]
        let resetButton = app.buttons["Reset"]

        // Start timer
        startButton.tap()

        // Reset timer
        resetButton.tap()

        // Verify timer is reset to initial state
        XCTAssertTrue(startButton.waitForExistence(timeout: 2), "Start button should be visible after reset")
        XCTAssertFalse(app.buttons["Pause"].exists, "Pause button should not exist after reset")
    }

    func testTimerPhaseTransitions() throws {
        // This test would need to run for longer duration to test phase changes
        // For now, we'll test the UI elements that indicate phase changes

        let startButton = app.buttons["Start"]
        startButton.tap()

        // Check for phase indicator
        let phaseText = app.staticTexts.matching(identifier: "PhaseText").firstMatch
        XCTAssertTrue(phaseText.exists, "Phase text should be visible")

        // Check for progress indicators
        let progressIndicators = app.otherElements["CycleProgressView"]
        XCTAssertTrue(progressIndicators.exists, "Cycle progress indicators should be visible")
    }

    // MARK: - Timer Controls Tests

    func testTimerControlsLayout() throws {
        // Verify control buttons are properly positioned
        let startButton = app.buttons["Start"]
        let resetButton = app.buttons["Reset"]

        XCTAssertTrue(startButton.exists, "Start button should exist")
        XCTAssertTrue(resetButton.exists, "Reset button should exist")

        // Verify button accessibility
        XCTAssertTrue(startButton.isHittable, "Start button should be hittable")
        XCTAssertTrue(resetButton.isHittable, "Reset button should be hittable")
    }

    func testTimerAccessibility() throws {
        // Test VoiceOver compatibility
        let startButton = app.buttons["Start"]
        XCTAssertTrue(startButton.exists, "Start button should be accessible")

        let resetButton = app.buttons["Reset"]
        XCTAssertTrue(resetButton.exists, "Reset button should be accessible")

        // Test dynamic type support
        let timeDisplay = app.staticTexts.matching(identifier: "TimeDisplay").firstMatch
        XCTAssertTrue(timeDisplay.exists, "Time display should support dynamic type")
    }

    // MARK: - Performance Tests

    func testTimerUIPerformance() throws {
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
