import XCTest

final class TimeBeamUITests: XCTestCase {

    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    override func tearDownWithError() throws {
        // Clean up after each test
    }

    // MARK: - Analytics Tab Tests

    func testAnalyticsTabNavigation() throws {
        // Navigate to Analytics tab
        let analyticsTab = app.tabBars.buttons["Analytics"]
        XCTAssertTrue(analyticsTab.exists, "Analytics tab should exist")
        analyticsTab.tap()

        // Verify Analytics view loads
        let analyticsNavigationBar = app.navigationBars["Analytics"]
        XCTAssertTrue(analyticsNavigationBar.exists, "Analytics navigation bar should appear")

        // Check for main content elements
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.exists, "Main scroll view should exist")
    }

    func testAnalyticsLoadingState() throws {
        // Navigate to Analytics
        app.tabBars.buttons["Analytics"].tap()

        // Initially should show loading/shimmer
        let shimmerView = app.otherElements.containing(.staticText, identifier: "ShimmerLoadingView").firstMatch
        // Note: ShimmerLoadingView might not have accessible identifiers, so we check for general loading behavior

        // Wait for data to load (adjust timeout as needed)
        let headerCard = app.staticTexts["Weekly?"]
        let exists = headerCard.waitForExistence(timeout: 10)
        XCTAssertTrue(exists, "Header card should load within 10 seconds")
    }

    func testAnalyticsHeaderCard() throws {
        app.tabBars.buttons["Analytics"].tap()

        // Wait for content to load
        let headerCard = app.staticTexts["Weekly?"]
        XCTAssertTrue(headerCard.waitForExistence(timeout: 10), "Header card should load")

        // Check header elements
        XCTAssertTrue(app.staticTexts["Your focus journey this week"].exists, "Header subtitle should exist")
        XCTAssertTrue(app.staticTexts["Deep work goal"].exists, "Deep work goal label should exist")

        // Check for progress ring (ActivityRing might not be directly accessible)
        // The ring is a ZStack with Circles, so we check for the progress text
        let progressText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '/ 20h'")).firstMatch
        XCTAssertTrue(progressText.exists, "Progress text should show 'Xh / 20h' format")
    }

    func testAnalyticsWeeklyChart() throws {
        app.tabBars.buttons["Analytics"].tap()

        // Wait for chart to load
        let chartTitle = app.staticTexts["Daily Focus"]
        XCTAssertTrue(chartTitle.waitForExistence(timeout: 10), "Chart title should load")

        // Check chart elements
        XCTAssertTrue(app.staticTexts["Focus Time"].exists, "Chart legend should exist")

        // Check for weekday labels (Mon, Tue, Wed, etc.)
        let mondayLabel = app.staticTexts["Mon"]
        XCTAssertTrue(mondayLabel.exists, "Monday label should exist in chart")

        // Check for average text
        let avgText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Avg'")).firstMatch
        XCTAssertTrue(avgText.exists, "Average text should exist")
    }

    func testAnalyticsSummaryCards() throws {
        app.tabBars.buttons["Analytics"].tap()

        // Wait for summary cards to load
        let todayCard = app.staticTexts["Today"]
        XCTAssertTrue(todayCard.waitForExistence(timeout: 10), "Today card should load")

        // Check all three summary cards exist
        XCTAssertTrue(app.staticTexts["Today"].exists, "Today card should exist")
        XCTAssertTrue(app.staticTexts["Weekly Total"].exists, "Weekly Total card should exist")
        XCTAssertTrue(app.staticTexts["Best Streak"].exists, "Best Streak card should exist")

        // Check card icons exist
        XCTAssertTrue(app.images["clock.fill"].exists, "Clock icon should exist")
        XCTAssertTrue(app.images["calendar"].exists, "Calendar icon should exist")
        XCTAssertTrue(app.images["flame.fill"].exists, "Flame icon should exist")

        // Check for session counts in Today card
        let sessionText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'sessions'")).firstMatch
        XCTAssertTrue(sessionText.exists, "Session count text should exist")
    }

    func testAnalyticsSessionHistory() throws {
        app.tabBars.buttons["Analytics"].tap()

        // Wait for session history to load
        let historyTitle = app.staticTexts["Recent Sessions"]
        XCTAssertTrue(historyTitle.waitForExistence(timeout: 10), "Session history title should load")

        // Check for session entries (at least some should exist)
        let focusText = app.staticTexts["Focus"]
        let breakText = app.staticTexts["Break"]

        // At least one type of session should exist
        let hasSessions = focusText.exists || breakText.exists
        XCTAssertTrue(hasSessions, "At least some session entries should exist")

        // Check for time stamps (HH:mm format)
        let timeRegex = try! NSRegularExpression(pattern: "\\d{2}:\\d{2}", options: [])
        let allLabels = app.staticTexts.allElementsBoundByIndex.map { $0.label }
        let hasTimeStamps = allLabels.contains { label in
            timeRegex.firstMatch(in: label, options: [], range: NSRange(location: 0, length: label.count)) != nil
        }
        XCTAssertTrue(hasTimeStamps, "Session timestamps should exist in HH:mm format")
    }

    func testAnalyticsScrolling() throws {
        app.tabBars.buttons["Analytics"].tap()

        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.exists, "Scroll view should exist")

        // Scroll down to see session history
        scrollView.swipeUp()

        // Check if session history is now visible
        let historyTitle = app.staticTexts["Recent Sessions"]
        XCTAssertTrue(historyTitle.exists, "Session history should be visible after scrolling")
    }

    func testAnalyticsTabSwitching() throws {
        // Start on Analytics tab
        app.tabBars.buttons["Analytics"].tap()
        XCTAssertTrue(app.navigationBars["Analytics"].exists, "Should be on Analytics tab")

        // Switch to another tab
        app.tabBars.buttons["Timer"].tap()
        XCTAssertFalse(app.navigationBars["Analytics"].exists, "Should not be on Analytics tab")

        // Switch back to Analytics
        app.tabBars.buttons["Analytics"].tap()
        XCTAssertTrue(app.navigationBars["Analytics"].exists, "Should be back on Analytics tab")

        // Content should still be there (basic state preservation check)
        XCTAssertTrue(app.staticTexts["Weekly?"].exists, "Header should still be visible")
    }

    func testAnalyticsErrorHandling() throws {
        // This test would require mocking network failures
        // For now, we'll test that error UI elements exist when needed

        app.tabBars.buttons["Analytics"].tap()

        // If an error occurs, these elements should appear:
        // - "Unable to Load Analytics" text
        // - "Try Again" button

        // Note: Actual error testing would require network mocking
        // This is a placeholder for error state verification
    }

    // MARK: - Performance Tests

    func testAnalyticsLoadingPerformance() throws {
        measure(metrics: [XCTClockMetric(), XCTCPUMetric(), XCTMemoryMetric()]) {
            app.tabBars.buttons["Analytics"].tap()

            // Wait for content to load
            let headerCard = app.staticTexts["Weekly?"]
            let loaded = headerCard.waitForExistence(timeout: 15)

            XCTAssertTrue(loaded, "Analytics should load within performance budget")
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
