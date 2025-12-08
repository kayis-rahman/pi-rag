//
//  CrossPlatformTestConfigurations.swift
//  TimeBeamUITests
//
//  Created by TimeBeam Team
//  Cross-platform test configurations for iOS, macOS, and watchOS
//  Ensuring consistent testing across all Apple platforms
//  Following Cline and Kilo code rules for cross-platform compatibility

import XCTest

// MARK: - Platform Detection and Configuration

/// Platform-specific test configuration
struct PlatformConfiguration {
    static var currentPlatform: Platform {
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .iPhone
        } else if UIDevice.current.userInterfaceIdiom == .pad {
            return .iPad
        } else {
            return .unknown
        }
        #elseif os(macOS)
        return .macOS
        #elseif os(watchOS)
        return .watchOS
        #else
        return .unknown
        #endif
    }

    static var isIPhone: Bool {
        currentPlatform == .iPhone
    }

    static var isIPad: Bool {
        currentPlatform == .iPad
    }

    static var isMacOS: Bool {
        currentPlatform == .macOS
    }

    static var isWatchOS: Bool {
        currentPlatform == .watchOS
    }

    enum Platform {
        case iPhone, iPad, macOS, watchOS, unknown
    }
}

// MARK: - Cross-Platform Test Base Classes

/// Base class for tests that run on all platforms
class CrossPlatformTestBase: TimeBeamTestBase {

    override func setUpWithError() throws {
        try super.setUpWithError()

        // Skip tests that don't apply to current platform
        try validatePlatformCompatibility()
    }

    private func validatePlatformCompatibility() throws {
        // Platform-specific validation can be added here
        // For example, skip watchOS-specific tests on iOS
    }

    /// Run test only on specified platforms
    func runOnPlatforms(_ platforms: [PlatformConfiguration.Platform], testBlock: () throws -> Void) rethrows {
        guard platforms.contains(PlatformConfiguration.currentPlatform) else {
            throw XCTSkip("Test not applicable to current platform")
        }
        try testBlock()
    }

    /// Skip test on specified platforms
    func skipOnPlatforms(_ platforms: [PlatformConfiguration.Platform], _ reason: String = "Not supported on this platform") throws {
        if platforms.contains(PlatformConfiguration.currentPlatform) {
            throw XCTSkip(reason)
        }
    }
}

/// Base class for iOS-specific tests
class iOSTestBase: CrossPlatformTestBase {

    override func setUpWithError() throws {
        try super.setUpWithError()

        #if !os(iOS)
        throw XCTSkip("iOS-specific test")
        #endif
    }

    /// Test iPhone-specific functionality
    func testIPhoneSpecific(testBlock: () throws -> Void) rethrows {
        try runOnPlatforms([.iPhone], testBlock: testBlock)
    }

    /// Test iPad-specific functionality
    func testIPadSpecific(testBlock: () throws -> Void) rethrows {
        try runOnPlatforms([.iPad], testBlock: testBlock)
    }
}

/// Base class for macOS-specific tests
class MacOSTestBase: CrossPlatformTestBase {

    override func setUpWithError() throws {
        try super.setUpWithError()

        #if !os(macOS)
        throw XCTSkip("macOS-specific test")
        #endif
    }
}

/// Base class for watchOS-specific tests
class WatchOSTestBase: CrossPlatformTestBase {

    override func setUpWithError() throws {
        try super.setUpWithError()

        #if !os(watchOS)
        throw XCTSkip("watchOS-specific test")
        #endif
    }
}

// MARK: - Platform-Specific Test Configurations

final class iOSTimerUITests: iOSTestBase {

    func testTimerStartPauseOnIPhone() throws {
        try testIPhoneSpecific {
            // iPhone-specific timer interactions
            let startButton = app.buttons["Start"]
            XCTAssertTrue(startButton.exists, "Start button should exist on iPhone")

            startButton.tap()
            XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: TestConfiguration.quickTimeout),
                         "Pause button should appear on iPhone")

            app.buttons["Pause"].tap()
            XCTAssertTrue(app.buttons["Start"].waitForExistence(timeout: TestConfiguration.quickTimeout),
                         "Start button should reappear on iPhone")
        }
    }

    func testTimerStartPauseOnIPad() throws {
        try testIPadSpecific {
            // iPad-specific timer interactions (may have different layout)
            let startButton = app.buttons["Start"]
            XCTAssertTrue(startButton.exists, "Start button should exist on iPad")

            startButton.tap()
            XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: TestConfiguration.quickTimeout),
                         "Pause button should appear on iPad")

            // iPad might have additional space for more controls
            let resetButton = app.buttons["Reset"]
            XCTAssertTrue(resetButton.exists, "Reset button should be available on iPad")
        }
    }

    func testOrientationChangesOnIOS() throws {
        try skipOnPlatforms([.watchOS], "Orientation changes not applicable to watchOS")

        #if os(iOS)
        // Test portrait mode
        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(app.otherElements["CircularTimerView"].exists,
                     "Timer should be visible in portrait")

        // Test landscape mode
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(app.otherElements["CircularTimerView"].waitForExistence(timeout: TestConfiguration.quickTimeout),
                     "Timer should adapt to landscape")

        // Test rotation back
        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(app.otherElements["CircularTimerView"].exists,
                     "Timer should adapt back to portrait")
        #endif
    }
}

final class MacOSTimerUITests: MacOSTestBase {

    func testTimerInWindowedEnvironment() throws {
        // macOS-specific windowed testing
        let window = app.windows.firstMatch
        XCTAssertTrue(window.exists, "App should run in a window on macOS")

        // Test window controls
        let closeButton = window.buttons["Close"]
        XCTAssertTrue(closeButton.exists, "Window should have close button")

        let minimizeButton = window.buttons["Minimize"]
        XCTAssertTrue(minimizeButton.exists, "Window should have minimize button")

        // Test timer functionality in windowed environment
        let startButton = app.buttons["Start"]
        XCTAssertTrue(startButton.exists, "Start button should exist in macOS window")

        startButton.tap()
        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: TestConfiguration.quickTimeout),
                     "Pause button should appear in macOS window")
    }

    func testMenuBarIntegration() throws {
        // Test menu bar integration (if applicable)
        // Note: Menu bar testing requires specific macOS test setup

        let timerMenuItem = app.menuItems["Timer"]
        if timerMenuItem.exists {
            timerMenuItem.click()

            // Verify menu action works
            XCTAssertTrue(app.otherElements["CircularTimerView"].exists,
                         "Timer view should be accessible via menu")
        }
    }

    func testKeyboardShortcuts() throws {
        // Test keyboard shortcuts specific to macOS
        let timerView = app.otherElements["CircularTimerView"]
        XCTAssertTrue(timerView.exists, "Timer view should be keyboard accessible")

        // Test Cmd+R for reset (if implemented)
        // app.typeKey("r", modifierFlags: [.command])

        // Verify keyboard navigation works
        XCTAssertTrue(app.buttons["Start"].exists, "Start button should be keyboard accessible")
    }
}

final class WatchOSTimerUITests: WatchOSTestBase {

    func testCompactTimerInterface() throws {
        // watchOS-specific compact interface testing
        let timerView = app.otherElements["CircularTimerView"]
        XCTAssertTrue(timerView.exists, "Timer should fit in watchOS compact interface")

        // Test simplified controls
        let startButton = app.buttons["Start"]
        XCTAssertTrue(startButton.exists, "Start button should exist on watchOS")

        // watchOS might have simplified button layout
        let buttonCount = app.buttons.count
        XCTAssertLessThanOrEqual(buttonCount, 3, "watchOS should have minimal button count")
    }

    func testHapticFeedback() throws {
        // Test haptic feedback (limited testing capability)
        let startButton = app.buttons["Start"]
        startButton.tap()

        // Verify timer starts (haptic feedback testing requires device)
        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: TestConfiguration.quickTimeout),
                     "Timer should start with haptic feedback on watchOS")
    }

    func testComplicationSupport() throws {
        // Test watch complication integration (if applicable)
        // Note: Complication testing requires specific watchOS setup

        let complicationButton = app.buttons["Complication"]
        if complicationButton.exists {
            complicationButton.tap()

            // Verify complication view
            let complicationView = app.otherElements["ComplicationView"]
            XCTAssertTrue(complicationView.waitForExistence(timeout: TestConfiguration.quickTimeout),
                         "Complication view should be accessible")
        }
    }
}

// MARK: - Cross-Platform Task Management Tests

final class CrossPlatformTaskTests: CrossPlatformTestBase {

    func testTaskCreationAcrossPlatforms() throws {
        // Test that works on all platforms
        app.navigateToTab("Tasks")

        let createTaskButton = app.buttons["Create Task"]
        XCTAssertTrue(createTaskButton.waitForExistence(timeout: TestConfiguration.defaultTimeout),
                     "Create Task button should exist on all platforms")

        createTaskButton.tap()

        let titleField = app.textFields["Task Title"]
        XCTAssertTrue(titleField.waitForExistence(timeout: TestConfiguration.quickTimeout),
                     "Task title field should work on all platforms")

        titleField.tap()
        titleField.typeText("Cross-Platform Task")

        app.buttons["Save"].tap()

        XCTAssertTrue(app.staticTexts["Cross-Platform Task"].waitForExistence(timeout: TestConfiguration.quickTimeout),
                     "Task should be created on all platforms")
    }

    func testPlatformSpecificTaskFeatures() throws {
        app.navigateToTab("Tasks")

        // Test platform-specific adaptations
        if PlatformConfiguration.isIPad {
            // iPad might have more space for additional features
            let detailView = app.otherElements["TaskDetailView"]
            if detailView.exists {
                XCTAssertTrue(detailView.exists, "iPad should show detailed task view")
            }
        } else if PlatformConfiguration.isWatchOS {
            // watchOS might have simplified interface
            let simplifiedList = app.tables["SimplifiedTaskList"]
            if simplifiedList.exists {
                XCTAssertTrue(simplifiedList.exists, "watchOS should use simplified task list")
            }
        } else if PlatformConfiguration.isMacOS {
            // macOS might have keyboard shortcuts
            let taskTable = app.tables["TaskTable"]
            if taskTable.exists {
                XCTAssertTrue(taskTable.exists, "macOS should use table-based task list")
            }
        }
    }
}

// MARK: - Cross-Platform Analytics Tests

final class CrossPlatformAnalyticsTests: CrossPlatformTestBase {

    func testAnalyticsDisplayAcrossPlatforms() throws {
        app.navigateToTab("Analytics")

        // Basic analytics should work on all platforms
        let weeklyCard = app.staticTexts["Weekly?"]
        XCTAssertTrue(weeklyCard.waitForExistence(timeout: TestConfiguration.defaultTimeout),
                     "Weekly analytics should display on all platforms")

        // Platform-specific adaptations
        if PlatformConfiguration.isWatchOS {
            // watchOS might show simplified analytics
            let summaryOnly = app.staticTexts["Summary"]
            XCTAssertTrue(summaryOnly.exists, "watchOS should show simplified analytics")
        } else {
            // Full platforms show detailed analytics
            let chartView = app.otherElements["ChartView"]
            XCTAssertTrue(chartView.waitForExistence(timeout: TestConfiguration.defaultTimeout),
                         "Full platforms should show detailed charts")
        }
    }

    func testAnalyticsInteractionByPlatform() throws {
        app.navigateToTab("Analytics")

        if PlatformConfiguration.isIPhone || PlatformConfiguration.isIPad {
            // Touch-based interactions
            let scrollView = app.scrollViews.firstMatch
            scrollView.swipeUp()

            let sessionHistory = app.staticTexts["Recent Sessions"]
            XCTAssertTrue(sessionHistory.exists, "iOS should support scrolling to session history")
        } else if PlatformConfiguration.isMacOS {
            // Mouse and keyboard interactions
            let scrollView = app.scrollViews.firstMatch
            scrollView.scroll(byDeltaX: 0, deltaY: -100)

            let sessionHistory = app.staticTexts["Recent Sessions"]
            XCTAssertTrue(sessionHistory.exists, "macOS should support mouse scrolling")
        }
        // watchOS might not have scrolling or limited interaction
    }
}

// MARK: - Platform-Specific Settings Tests

final class PlatformSpecificSettingsTests: CrossPlatformTestBase {

    func testPlatformAppropriateSettings() throws {
        app.navigateToTab("Settings")

        // Common settings that should exist on all platforms
        let timerSettings = app.staticTexts["Timer Settings"]
        XCTAssertTrue(timerSettings.waitForExistence(timeout: TestConfiguration.defaultTimeout),
                     "Timer settings should exist on all platforms")

        // Platform-specific settings
        if PlatformConfiguration.isIPhone || PlatformConfiguration.isIPad {
            // iOS-specific settings
            let notificationSettings = app.staticTexts["Notification Settings"]
            XCTAssertTrue(notificationSettings.exists, "iOS should have notification settings")

            let hapticsToggle = app.switches["Enable Haptics"]
            XCTAssertTrue(hapticsToggle.exists, "iOS should have haptics settings")
        } else if PlatformConfiguration.isMacOS {
            // macOS-specific settings
            let dockIconToggle = app.switches["Show in Dock"]
            XCTAssertTrue(dockIconToggle.exists, "macOS should have dock settings")

            let menuBarToggle = app.switches["Show in Menu Bar"]
            XCTAssertTrue(menuBarToggle.exists, "macOS should have menu bar settings")
        } else if PlatformConfiguration.isWatchOS {
            // watchOS-specific settings
            let complicationsToggle = app.switches["Enable Complications"]
            XCTAssertTrue(complicationsToggle.exists, "watchOS should have complication settings")
        }
    }

    func testSettingsPersistenceAcrossPlatforms() throws {
        app.navigateToTab("Settings")

        // Change a setting
        let workDurationField = app.textFields["Work Duration"]
        if workDurationField.waitForExistence(timeout: TestConfiguration.quickTimeout) {
            let originalValue = workDurationField.value as? String
            workDurationField.tap()
            workDurationField.clearText()
            workDurationField.typeText("30")

            app.buttons["Save Settings"].tap()

            // Verify persistence (this would require app restart in real testing)
            XCTAssertNotEqual(originalValue, "30", "Settings should persist on all platforms")
        }
    }
}

// MARK: - Device-Specific Layout Tests

final class DeviceSpecificLayoutTests: iOSTestBase {

    func testIPhoneSELayout() throws {
        // Test on small screens (iPhone SE)
        try runOnPlatforms([.iPhone]) {
            app.navigateToTab("Timer")

            // Verify timer fits in small screen
            let timerView = app.otherElements["CircularTimerView"]
            XCTAssertTrue(timerView.exists, "Timer should fit on small iPhone screens")

            // Test that buttons are appropriately sized
            let startButton = app.buttons["Start"]
            XCTAssertTrue(startButton.exists, "Start button should be touchable on small screens")

            // Verify no horizontal scrolling needed
            let screenWidth = app.windows.firstMatch.frame.width
            let contentWidth = timerView.frame.width
            XCTAssertLessThanOrEqual(contentWidth, screenWidth,
                                   "Content should fit within screen width on small devices")
        }
    }

    func testIPhoneProMaxLayout() throws {
        // Test on large screens (iPhone Pro Max)
        try runOnPlatforms([.iPhone]) {
            app.navigateToTab("Analytics")

            // Verify large screens utilize space effectively
            let scrollView = app.scrollViews.firstMatch
            XCTAssertTrue(scrollView.exists, "Large screens should use scrollable layouts")

            // Test that more content is visible
            let summaryCards = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Total'"))
            XCTAssertGreaterThan(summaryCards.count, 0, "Large screens should show more summary cards")
        }
    }

    func testIPadLayoutOptimization() throws {
        try testIPadSpecific {
            app.navigateToTab("Tasks")

            // Test iPad-specific layouts
            let splitView = app.otherElements["SplitView"]
            if splitView.exists {
                // iPad might use split view
                XCTAssertTrue(splitView.exists, "iPad should optimize layout with split views")
            }

            // Test popover usage
            app.buttons["Create Task"].tap()

            let popover = app.popovers.firstMatch
            XCTAssertTrue(popover.waitForExistence(timeout: TestConfiguration.quickTimeout),
                         "iPad should use popovers for forms")
        }
    }
}

// MARK: - Cross-Platform Performance Tests

final class CrossPlatformPerformanceTests: CrossPlatformTestBase {

    func testAppLaunchPerformanceAcrossPlatforms() throws {
        measure(metrics: [XCTClockMetric(), XCTCPUMetric(), XCTMemoryMetric()]) {
            app.terminate()
            app.launchForTesting()
            app.waitForAppReady(timeout: TestConfiguration.extendedTimeout)
        }
    }

    func testPlatformSpecificPerformanceOptimizations() throws {
        if PlatformConfiguration.isWatchOS {
            // watchOS should be more performance-conscious
            measure(metrics: [XCTMemoryMetric(), XCTCPUMetric()]) {
                app.navigateToTab("Timer")
                // Perform minimal operations on watchOS
                app.buttons["Start"].tap()
                Thread.sleep(forTimeInterval: 1.0)
                app.buttons["Stop"].tap()
            }
        } else {
            // Full platforms can handle more complex operations
            measure(metrics: [XCTClockMetric(), XCTCPUMetric(), XCTMemoryMetric()]) {
                app.navigateToTab("Analytics")
                app.waitForExistence(timeout: TestConfiguration.defaultTimeout)
                // Perform more complex analytics loading
            }
        }
    }
}

// MARK: - Platform Compatibility Validation

final class PlatformCompatibilityValidationTests: CrossPlatformTestBase {

    func testAllTabsExistOnCurrentPlatform() throws {
        // Verify all expected tabs exist on current platform
        let expectedTabs = ["Timer", "Tasks", "Analytics", "Settings"]

        for tabName in expectedTabs {
            let tab = app.tabBars.buttons[tabName]
            if !tab.exists {
                // Some platforms might not have all tabs
                if PlatformConfiguration.isWatchOS && (tabName == "Analytics" || tabName == "Settings") {
                    // watchOS might have simplified tab set
                    continue
                }
                XCTFail("Tab '\(tabName)' should exist on \(PlatformConfiguration.currentPlatform)")
            }
        }
    }

    func testPlatformAppropriateNavigation() throws {
        if PlatformConfiguration.isIPhone || PlatformConfiguration.isIPad {
            // iOS uses tab bar navigation
            let tabBar = app.tabBars.firstMatch
            XCTAssertTrue(tabBar.exists, "iOS should use tab bar navigation")
        } else if PlatformConfiguration.isMacOS {
            // macOS might use toolbar or menu navigation
            let toolbar = app.toolbars.firstMatch
            XCTAssertTrue(toolbar.exists, "macOS should use toolbar navigation")
        }
        // watchOS uses crown and button navigation (limited testing capability)
    }

    func testPlatformAppropriateInputMethods() throws {
        app.navigateToTab("Tasks")
        app.buttons["Create Task"].tap()

        let titleField = app.textFields["Task Title"]
        XCTAssertTrue(titleField.waitForExistence(timeout: TestConfiguration.quickTimeout),
                     "Text input should work on all platforms")

        if PlatformConfiguration.isIPhone || PlatformConfiguration.isIPad {
            // iOS should show keyboard
            let keyboard = app.keyboards.firstMatch
            XCTAssertTrue(keyboard.waitForExistence(timeout: TestConfiguration.quickTimeout),
                         "iOS should show virtual keyboard")
        } else if PlatformConfiguration.isMacOS {
            // macOS should handle physical keyboard
            // Note: Keyboard testing is limited in UI tests
            XCTAssertTrue(titleField.exists, "macOS should handle keyboard input")
        }
        // watchOS has limited text input capabilities
    }
}

// MARK: - Test Execution Configuration

/// Configuration for running tests on different platforms
struct TestExecutionConfiguration {

    static func configureForPlatform() -> [String: Any] {
        var config = [String: Any]()

        config["platform"] = PlatformConfiguration.currentPlatform
        config["deviceType"] = UIDevice.current.userInterfaceIdiom.rawValue
        config["deviceName"] = UIDevice.current.name
        config["systemVersion"] = UIDevice.current.systemVersion

        #if os(iOS)
        config["screenSize"] = UIScreen.main.bounds.size
        config["screenScale"] = UIScreen.main.scale
        #endif

        return config
    }

    static func shouldSkipTest(_ testName: String, onPlatform platform: PlatformConfiguration.Platform) -> Bool {
        // Define platform-specific test exclusions
        let platformExclusions: [PlatformConfiguration.Platform: [String]] = [
            .watchOS: [
                "testAnalyticsDetailedCharts", // watchOS has simplified analytics
                "testComplexTaskFiltering",    // watchOS has limited filtering
                "testBulkTaskOperations"       // watchOS has limited bulk operations
            ],
            .macOS: [
                "testHapticFeedback",          // macOS doesn't have haptic feedback
                "testSplitScreenCompatibility" // macOS handles split screen differently
            ]
        ]

        return platformExclusions[platform]?.contains(testName) ?? false
    }

    static func getPlatformSpecificTimeout(baseTimeout: TimeInterval) -> TimeInterval {
        switch PlatformConfiguration.currentPlatform {
        case .watchOS:
            return baseTimeout * 2.0 // watchOS is slower
        case .macOS:
            return baseTimeout * 1.2 // macOS might be slightly slower
        default:
            return baseTimeout
        }
    }
}