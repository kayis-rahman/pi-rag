import XCTest

final class iOSSettingsUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launchEnvironment = ["SYNAPSE_UI_TESTING": "1"]
        app.launch()
        XCTAssertTrue(app.buttons["home-capture-ui-testing"].waitForExistence(timeout: 15))
    }

    private func openSettings() {
        app.buttons["workspace-settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
    }

    func testSettingsHubShowsPrimaryDestinations() {
        openSettings()
        XCTAssertTrue(app.buttons["settings-account"].exists)
        XCTAssertTrue(app.buttons["settings-focus"].exists)
        XCTAssertTrue(app.buttons["settings-sound-haptics"].exists)
        XCTAssertTrue(app.buttons["settings-appearance"].exists)
        XCTAssertTrue(app.buttons["settings-support-about"].exists)
        XCTAssertTrue(app.buttons["settings-data-privacy"].exists)
    }

    func testFocusSettingsShowsSafeTimerControls() {
        openSettings()
        app.buttons["settings-focus"].tap()
        XCTAssertTrue(app.navigationBars["Focus"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Focus duration"].exists)
        XCTAssertTrue(app.staticTexts["Short break"].exists)
        XCTAssertTrue(app.staticTexts["Long break"].exists)
        XCTAssertTrue(app.switches["settings-auto-start"].exists)
    }

    func testDataPrivacyRequiresConfirmation() {
        openSettings()
        app.buttons["settings-data-privacy"].tap()
        XCTAssertTrue(app.navigationBars["Data & Privacy"].waitForExistence(timeout: 5))
        app.buttons["settings-clear-history"].tap()
        XCTAssertTrue(app.buttons["Clear history"].waitForExistence(timeout: 3))
    }
}
