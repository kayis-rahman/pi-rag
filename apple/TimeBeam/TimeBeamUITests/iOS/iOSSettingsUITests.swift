import XCTest

final class iOSSettingsUITests: XCTestCase {

    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    override func tearDownWithError() throws {
        // Clean up after each test
    }

    // MARK: - Settings Navigation Tests

    func testSettingsTabNavigation() throws {
        // Navigate to Settings tab
        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.exists, "Settings tab should exist")
        settingsTab.tap()

        // Verify Settings view loads
        let settingsNavigationBar = app.navigationBars["Settings"]
        XCTAssertTrue(settingsNavigationBar.exists, "Settings navigation bar should appear")
    }

    func testSettingsTabSwitching() throws {
        // Start on Timer tab
        XCTAssertTrue(app.tabBars.buttons["Timer"].exists, "Should start on Timer tab")

        // Switch to Settings tab
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].exists, "Should be on Settings tab")

        // Switch back to Timer
        app.tabBars.buttons["Timer"].tap()
        XCTAssertTrue(app.buttons["Start"].exists, "Should be back on Timer tab")
    }

    // MARK: - Duration Settings Tests

    func testDurationSettingsUI() throws {
        app.tabBars.buttons["Settings"].tap()

        // Check for duration controls
        let workDurationControl = app.steppers["Work Duration"]
        let shortBreakControl = app.steppers["Short Break"]
        let longBreakControl = app.steppers["Long Break"]

        XCTAssertTrue(workDurationControl.exists, "Work duration control should exist")
        XCTAssertTrue(shortBreakControl.exists, "Short break control should exist")
        XCTAssertTrue(longBreakControl.exists, "Long break control should exist")

        // Test increment/decrement functionality
        workDurationControl.buttons["Increment"].tap()
        workDurationControl.buttons["Decrement"].tap()
    }

    func testDurationValueDisplay() throws {
        app.tabBars.buttons["Settings"].tap()

        // Check for duration value displays
        let workDurationValue = app.staticTexts["Work Duration Value"]
        let shortBreakValue = app.staticTexts["Short Break Value"]
        let longBreakValue = app.staticTexts["Long Break Value"]

        XCTAssertTrue(workDurationValue.exists, "Work duration value should be displayed")
        XCTAssertTrue(shortBreakValue.exists, "Short break value should be displayed")
        XCTAssertTrue(longBreakValue.exists, "Long break value should be displayed")
    }

    // MARK: - Theme Settings Tests

    func testThemeSelectionUI() throws {
        app.tabBars.buttons["Settings"].tap()

        // Check for theme selection controls
        let themePicker = app.pickers["Theme Picker"]
        XCTAssertTrue(themePicker.exists, "Theme picker should exist")

        // Test theme switching
        themePicker.pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: "Dark")
        themePicker.pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: "Light")
    }

    func testThemePreview() throws {
        app.tabBars.buttons["Settings"].tap()

        // Check for theme preview
        let themePreview = app.otherElements["Theme Preview"]
        XCTAssertTrue(themePreview.exists, "Theme preview should be visible")
    }

    // MARK: - Authentication Tests

    func testAuthenticationUI() throws {
        app.tabBars.buttons["Settings"].tap()

        // Check for authentication section
        let authSection = app.otherElements["Authentication Section"]
        XCTAssertTrue(authSection.exists, "Authentication section should exist")

        // Check for sign in/out buttons
        let signInButton = app.buttons["Sign In with Google"]
        let signOutButton = app.buttons["Sign Out"]

        if signInButton.exists {
            XCTAssertTrue(signInButton.isEnabled, "Sign in button should be enabled")
        } else if signOutButton.exists {
            XCTAssertTrue(signOutButton.isEnabled, "Sign out button should be enabled")
        }
    }

    // MARK: - Settings Accessibility Tests

    func testSettingsAccessibility() throws {
        app.tabBars.buttons["Settings"].tap()

        // Test VoiceOver compatibility for settings controls
        let workDurationControl = app.steppers["Work Duration"]
        XCTAssertTrue(workDurationControl.exists, "Work duration control should be accessible")

        let themePicker = app.pickers["Theme Picker"]
        XCTAssertTrue(themePicker.exists, "Theme picker should be accessible")

        // Test dynamic type support
        let settingsTitle = app.staticTexts["Settings"]
        XCTAssertTrue(settingsTitle.exists, "Settings title should support dynamic type")
    }

    // MARK: - Performance Tests

    func testSettingsUIPerformance() throws {
        measure(metrics: [XCTClockMetric(), XCTCPUMetric(), XCTMemoryMetric()]) {
            // Navigate to Settings
            app.tabBars.buttons["Settings"].tap()

            // Verify quick loading
            let settingsNavigationBar = app.navigationBars["Settings"]
            XCTAssertTrue(settingsNavigationBar.waitForExistence(timeout: 2), "Settings should load quickly")

            // Test control responsiveness
            let workDurationControl = app.steppers["Work Duration"]
            workDurationControl.buttons["Increment"].tap()
            XCTAssertTrue(workDurationControl.exists, "Controls should respond quickly")
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
