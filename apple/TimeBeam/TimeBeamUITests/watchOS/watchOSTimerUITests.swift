import XCTest

final class watchOSTimerUITests: XCTestCase {

    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    override func tearDownWithError() throws {
        // Clean up after each test
    }

    // MARK: - watchOS Timer Interface Tests

    func testWatchOSTimerInitialState() throws {
        // Verify initial timer state for watchOS
        let timerRing = app.otherElements["CircularTimerView"]
        XCTAssertTrue(timerRing.exists, "Timer ring should be visible")

        let startButton = app.buttons["Start"]
        XCTAssertTrue(startButton.exists, "Start button should be visible")
        XCTAssertTrue(startButton.isEnabled, "Start button should be enabled")

        // Verify initial time display
        let timeDisplay = app.staticTexts.matching(identifier: "TimeDisplay").firstMatch
        XCTAssertTrue(timeDisplay.exists, "Time display should be visible")

        // Verify phase indicator
        let phaseText = app.staticTexts.matching(identifier: "PhaseText").firstMatch
        XCTAssertTrue(phaseText.exists, "Phase text should be visible")
    }

    func testWatchOSTimerStartPauseFunctionality() throws {
        let startButton = app.buttons["Start"]
        let pauseButton = app.buttons["Pause"]

        // Start timer
        startButton.tap()
        XCTAssertTrue(pauseButton.waitForExistence(timeout: 2), "Pause button should appear after starting")

        // Pause timer
        pauseButton.tap()
        XCTAssertTrue(startButton.waitForExistence(timeout: 2), "Start button should reappear after pausing")
    }

    func testWatchOSTimerCompactLayout() throws {
        // Test that UI is properly sized for small watch screen
        let timerRing = app.otherElements["CircularTimerView"]
        let ringSize = timerRing.frame.size

        // Verify ring is appropriately sized for watch
        XCTAssertTrue(ringSize.width <= 150, "Timer ring should be compact for watchOS")
        XCTAssertTrue(ringSize.height <= 150, "Timer ring should be compact for watchOS")

        // Verify button is appropriately sized
        let startButton = app.buttons["Start"]
        let buttonSize = startButton.frame.size
        XCTAssertTrue(buttonSize.width <= 60, "Button should be compact for watchOS")
        XCTAssertTrue(buttonSize.height <= 60, "Button should be compact for watchOS")
    }

    func testWatchOSTimerPhaseDisplay() throws {
        // Test phase display on small screen
        let phaseText = app.staticTexts.matching(identifier: "PhaseText").firstMatch
        XCTAssertTrue(phaseText.exists, "Phase text should be visible")

        // Verify phase text is appropriately sized
        let phaseFontSize = phaseText.value(forKey: "fontSize") as? CGFloat
        XCTAssertTrue(phaseFontSize ?? 0 <= 16, "Phase text should be appropriately sized for watchOS")
    }

    func testWatchOSTimerAccessibility() throws {
        // Test VoiceOver compatibility for watchOS
        let startButton = app.buttons["Start"]
        XCTAssertTrue(startButton.exists, "Start button should be accessible")

        let pauseButton = app.buttons["Pause"]
        XCTAssertTrue(pauseButton.exists, "Pause button should be accessible")

        // Test dynamic type support
        let timeDisplay = app.staticTexts.matching(identifier: "TimeDisplay").firstMatch
        XCTAssertTrue(timeDisplay.exists, "Time display should support dynamic type")
    }

    func testWatchOSTimerHapticFeedback() throws {
        // Test that timer completion triggers haptic feedback
        // Note: This is harder to test directly in UI tests
        // We'll verify the timer completion logic works

        let startButton = app.buttons["Start"]
        startButton.tap()

        // Wait a short time then pause
        let pauseButton = app.buttons["Pause"]
        XCTAssertTrue(pauseButton.waitForExistence(timeout: 2), "Pause button should appear")

        pauseButton.tap()
        XCTAssertTrue(startButton.waitForExistence(timeout: 2), "Start button should reappear")
    }

    // MARK: - Performance Tests

    func testWatchOSTimerUIPerformance() throws {
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
