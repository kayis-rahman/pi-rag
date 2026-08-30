import XCTest

final class GTDWorkspaceUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launchEnvironment = ["SYNAPSE_UI_TESTING": "1"]
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["home-capture-ui-testing"].waitForExistence(timeout: 15))
    }

    func testHomeTaskOpensDetailsAndSaves() throws {
        relaunch(prefilledCaptureTitle: "Email the client today")
        let capture = app.buttons["home-capture-ui-testing"]
        XCTAssertTrue(capture.waitForExistence(timeout: 15))
        capture.tap()

        let titleField = app.textFields["capture-title-field"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5))
        titleField.tap()
        _ = app.keyboards.firstMatch.waitForExistence(timeout: 3)
        XCTAssertEqual(titleField.value as? String, "Email the client today")
        let saveCapture = app.buttons["Save"]
        XCTAssertTrue(saveCapture.waitForExistence(timeout: 5))
        XCTAssertTrue(waitForEnabled(saveCapture, timeout: 5))
        saveCapture.tap()
        let confirmCapture = app.buttons["Confirm"]
        XCTAssertTrue(confirmCapture.waitForExistence(timeout: 10))
        confirmCapture.tap()

        let inboxTab = app.buttons["Inbox"]
        XCTAssertTrue(inboxTab.waitForExistence(timeout: 5))
        inboxTab.tap()

        let task = app.staticTexts["Email the client today"].firstMatch
        XCTAssertTrue(task.waitForExistence(timeout: 10))
        task.tap()

        XCTAssertTrue(app.navigationBars["Task details"].waitForExistence(timeout: 5))
        let detailTitle = app.textFields["task-detail-title"]
        XCTAssertTrue(detailTitle.waitForExistence(timeout: 5))
        app.buttons["task-detail-save"].tap()

        XCTAssertTrue(app.navigationBars["Task details"].waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Email the client today"].waitForExistence(timeout: 5))
    }

    func testDailyBriefingShowsPositiveEmptyStateOnDevice() throws {
        let briefingButton = app.buttons["daily-briefing-button"]
        XCTAssertTrue(briefingButton.waitForExistence(timeout: 10))
        briefingButton.tap()

        XCTAssertTrue(app.navigationBars["Daily briefing"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["All clear"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["All clear — nothing is due today."].exists)
    }

    func testEmptyCaptureCannotBeSaved() throws {
        relaunch(prefilledCaptureTitle: "")
        app.buttons["home-capture-ui-testing"].tap()

        let saveCapture = app.buttons["Save"]
        XCTAssertTrue(saveCapture.waitForExistence(timeout: 5))
        XCTAssertFalse(saveCapture.isEnabled)
    }

    func testWhitespaceOnlyCaptureCannotBeSaved() throws {
        relaunch(prefilledCaptureTitle: "   \t  ")
        app.buttons["home-capture-ui-testing"].tap()

        let saveCapture = app.buttons["Save"]
        XCTAssertTrue(saveCapture.waitForExistence(timeout: 5))
        XCTAssertFalse(saveCapture.isEnabled)
    }

    func testSpecialCharactersEmojiAndNonEnglishCaptureAreVisibleInInbox() throws {
        captureAndAssertInbox("Fix bug #123 @ 50% done!")
        relaunch(prefilledCaptureTitle: "Buy 🥛 and 🍞")
        captureAndAssertInbox("Buy 🥛 and 🍞")
        relaunch(prefilledCaptureTitle: "Acheter du lait pour demain")
        captureAndAssertInbox("Acheter du lait pour demain")
    }

    func testLongCaptureIsAcceptedAndStoredInInbox() throws {
        let title = String(repeating: "Review the project notes and decide the next step. ", count: 15)
        captureAndAssertInbox(title)

        XCTAssertTrue(app.staticTexts["To process"].waitForExistence(timeout: 5))
    }

    func testDuplicateRapidCapturesCreateTwoInboxItems() throws {
        let title = "Test duplicate capture"
        relaunch(prefilledCaptureTitle: title)
        captureAndAssertInbox(title)
        app.buttons["inbox-capture-button"].tap()
        confirmPrefilledCapture(title)

        XCTAssertEqual(app.staticTexts.matching(NSPredicate(format: "label == %@", title)).count, 2)
    }

    func testTenSequentialCapturesAreNotDropped() throws {
        let title = "Rapid capture"
        relaunch(prefilledCaptureTitle: title)
        captureAndAssertInbox(title)
        for _ in 1...9 {
            app.buttons["inbox-capture-button"].tap()
            confirmPrefilledCapture(title)
        }

        XCTAssertEqual(app.staticTexts.matching(NSPredicate(format: "label == %@", title)).count, 10)
    }

    func testCaptureDuringWeeklyReviewRemainsInInbox() throws {
        let title = "Capture while in progress"
        relaunch(prefilledCaptureTitle: title)
        openReviewTab()
        XCTAssertTrue(app.buttons["start-weekly-review"].waitForExistence(timeout: 5))
        app.buttons["start-weekly-review"].tap()
        XCTAssertTrue(app.buttons["weekly-review-step-0"].waitForExistence(timeout: 5))

        app.buttons["Today"].tap()
        app.buttons["home-capture-ui-testing"].tap()
        confirmPrefilledCapture(title)
        app.buttons["Inbox"].tap()

        XCTAssertTrue(app.staticTexts[title].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Review"].exists)
    }

    func testUnsubmittedCaptureDoesNotCreatePartialItemAfterRelaunch() throws {
        let title = "Draft that should not persist"
        relaunch(prefilledCaptureTitle: title)
        app.buttons["home-capture-ui-testing"].tap()
        XCTAssertTrue(app.textFields["capture-title-field"].waitForExistence(timeout: 5))

        app.terminate()
        app.launchArguments = ["-ui-testing"]
        app.launchEnvironment = [
            "SYNAPSE_UI_TESTING": "1",
            "SYNAPSE_UI_TEST_CAPTURE_TITLE": title
        ]
        app.launch()
        XCTAssertTrue(app.buttons["home-capture-ui-testing"].waitForExistence(timeout: 15))
        app.buttons["Inbox"].tap()

        XCTAssertFalse(app.staticTexts[title].exists)
    }

    func testInboxCaptureAppearsInToProcessList() throws {
        relaunch(prefilledCaptureTitle: "Remember the garden lights")
        let inboxTab = app.buttons["Inbox"]
        XCTAssertTrue(inboxTab.waitForExistence(timeout: 15))
        inboxTab.tap()

        let capture = app.buttons["inbox-capture-button"]
        XCTAssertTrue(capture.waitForExistence(timeout: 5))
        capture.tap()

        let titleField = app.textFields["capture-title-field"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5))
        titleField.tap()
        _ = app.keyboards.firstMatch.waitForExistence(timeout: 3)
        XCTAssertEqual(titleField.value as? String, "Remember the garden lights")
        let saveCapture = app.buttons["Save"]
        XCTAssertTrue(saveCapture.waitForExistence(timeout: 5))
        XCTAssertTrue(waitForEnabled(saveCapture, timeout: 5))
        saveCapture.tap()
        XCTAssertTrue(app.buttons["Confirm"].waitForExistence(timeout: 10))
        app.buttons["Confirm"].tap()

        XCTAssertTrue(app.staticTexts["Remember the garden lights"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["To process"].exists)
    }

    func testCaptureShowsEditableConfirmationWithAllCategories() throws {
        relaunch(prefilledCaptureTitle: "Call dentist Tuesday")
        app.buttons["home-capture-ui-testing"].tap()

        let saveCapture = app.buttons["Save"]
        XCTAssertTrue(saveCapture.waitForExistence(timeout: 5))
        XCTAssertTrue(waitForEnabled(saveCapture, timeout: 5))
        saveCapture.tap()

        XCTAssertTrue(app.navigationBars["Confirm capture"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["capture-category-inbox"].exists)
        XCTAssertTrue(app.buttons["capture-category-nextAction"].exists)
        XCTAssertTrue(app.buttons["capture-category-waitingFor"].exists)
        XCTAssertTrue(app.buttons["capture-category-somedayMaybe"].exists)
        XCTAssertTrue(app.textFields["capture-confirmation-title"].exists)

        app.buttons["capture-category-waitingFor"].tap()
        app.buttons["Confirm"].tap()
    }

    func testCancellingConfirmationLeavesCaptureInInbox() throws {
        relaunch(prefilledCaptureTitle: "Book dentist")
        app.buttons["home-capture-ui-testing"].tap()

        let saveCapture = app.buttons["Save"]
        XCTAssertTrue(waitForEnabled(saveCapture, timeout: 5))
        saveCapture.tap()
        XCTAssertTrue(app.buttons["Cancel"].waitForExistence(timeout: 10))
        app.buttons["Cancel"].tap()

        app.buttons["Inbox"].tap()
        XCTAssertTrue(app.staticTexts["Book dentist"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["To process"].exists)
    }

    func testInboxSearchSurfaceIsAccessible() throws {
        relaunch(prefilledCaptureTitle: "A searchable capture", forceInbox: true)
        let inboxTab = app.buttons["Inbox"]
        XCTAssertTrue(inboxTab.waitForExistence(timeout: 15))
        inboxTab.tap()

        let searchField = app.textFields["Search captures"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        XCTAssertTrue(searchField.isHittable)
    }

    private func waitForEnabled(_ element: XCUIElement, timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "isEnabled == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }

    private func captureAndAssertInbox(_ title: String) {
        relaunch(prefilledCaptureTitle: title)
        app.buttons["home-capture-ui-testing"].tap()
        confirmPrefilledCapture(title)
        app.buttons["Inbox"].tap()
        XCTAssertTrue(app.staticTexts[title].waitForExistence(timeout: 10))
    }

    private func confirmPrefilledCapture(_ title: String) {
        let titleField = app.textFields["capture-title-field"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5))
        XCTAssertEqual(titleField.value as? String, title)
        let saveCapture = app.buttons["Save"]
        XCTAssertTrue(waitForEnabled(saveCapture, timeout: 5))
        saveCapture.tap()
        let confirmCapture = app.buttons["Confirm"]
        XCTAssertTrue(confirmCapture.waitForExistence(timeout: 10))
        confirmCapture.tap()
    }

    private func relaunch(prefilledCaptureTitle: String, forceInbox: Bool = false) {
        app.terminate()
        app.launchArguments = ["-ui-testing"]
        var environment = [
            "SYNAPSE_UI_TESTING": "1",
            "SYNAPSE_UI_TEST_CAPTURE_TITLE": prefilledCaptureTitle
        ]
        if forceInbox {
            environment["SYNAPSE_UI_TEST_FORCE_INBOX"] = "1"
        }
        app.launchEnvironment = environment
        app.launch()
        XCTAssertTrue(app.buttons["home-capture-ui-testing"].waitForExistence(timeout: 15))
    }

    private func relaunchWithProjectAndAreaFixtures() {
        app.terminate()
        app.launchArguments = ["-ui-testing"]
        app.launchEnvironment = [
            "SYNAPSE_UI_TESTING": "1",
            "SYNAPSE_UI_TEST_SEED_PROJECTS_AREAS": "1"
        ]
        app.launch()
        XCTAssertTrue(app.buttons["home-capture-ui-testing"].waitForExistence(timeout: 15))
    }

    private func openReviewTab() {
        let reviewTab = app.tabBars.buttons["Review"]
        if reviewTab.waitForExistence(timeout: 3) {
            reviewTab.tap()
            return
        }

        let moreTab = app.tabBars.buttons["More"]
        XCTAssertTrue(moreTab.waitForExistence(timeout: 12))
        moreTab.tap()

        let reviewRow = app.staticTexts["Review"].firstMatch
        XCTAssertTrue(reviewRow.waitForExistence(timeout: 5))
        reviewRow.tap()
    }

    func testInboxTriageButtonIsPresentAndAccessible() throws {
        let inboxTab = app.buttons["Inbox"]
        XCTAssertTrue(inboxTab.waitForExistence(timeout: 15))
        inboxTab.tap()

        let triageButton = app.buttons["inbox-triage-button"]
        XCTAssertTrue(triageButton.waitForExistence(timeout: 5))
        XCTAssertEqual(triageButton.label, "Triage")
    }

    func testTriageShowsFutureNextActionInResultsAndGTDList() throws {
        let title = "Email the client tomorrow about the work plan"
        relaunch(prefilledCaptureTitle: title, forceInbox: true)
        app.buttons["Inbox"].tap()
        app.buttons["inbox-capture-button"].tap()

        let titleField = app.textFields["capture-title-field"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5))
        XCTAssertEqual(titleField.value as? String, title)
        let saveCapture = app.buttons["Save"]
        XCTAssertTrue(waitForEnabled(saveCapture, timeout: 5))
        saveCapture.tap()
        XCTAssertTrue(app.buttons["Confirm"].waitForExistence(timeout: 10))
        app.buttons["Confirm"].tap()
        XCTAssertTrue(app.staticTexts[title].waitForExistence(timeout: 10))

        let triageButton = app.buttons["inbox-triage-button"]
        XCTAssertTrue(triageButton.waitForExistence(timeout: 5))
        triageButton.tap()

        XCTAssertTrue(app.navigationBars["Sorted for you"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts["Next Action"].exists)
        XCTAssertTrue(app.staticTexts[title].exists)
        let allLists = app.buttons["triage-results-all-lists"]
        XCTAssertTrue(allLists.waitForExistence(timeout: 5))
        allLists.tap()

        XCTAssertTrue(app.navigationBars["GTD Lists"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Next Action"].exists)
        XCTAssertTrue(app.staticTexts[title].waitForExistence(timeout: 5))
    }

    func testWeeklyReviewStartsWithTheStructuredChecklist() throws {
        openReviewTab()

        XCTAssertTrue(app.navigationBars["Weekly Review"].waitForExistence(timeout: 5))
        let startReview = app.buttons["start-weekly-review"]
        XCTAssertTrue(startReview.waitForExistence(timeout: 5))
        startReview.tap()

        XCTAssertTrue(app.buttons["weekly-review-step-0"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["weekly-review-step-1"].exists)
        XCTAssertTrue(app.buttons["weekly-review-step-2"].exists)
        XCTAssertTrue(app.buttons["weekly-review-step-3"].exists)
        XCTAssertTrue(app.buttons["weekly-review-step-4"].exists)
        XCTAssertTrue(app.buttons["weekly-review-step-5"].exists)
    }

    func testWeeklyReviewCanSkipEveryStepAndShowsPartialCompletion() throws {
        openReviewTab()
        let startReview = app.buttons["start-weekly-review"]
        XCTAssertTrue(startReview.waitForExistence(timeout: 5))
        startReview.tap()

        for index in 0...5 {
            let skip = app.buttons
                .matching(NSPredicate(format: "label == 'Skip' AND isEnabled == true"))
                .firstMatch
            XCTAssertTrue(
                skip.waitForExistence(timeout: 5),
                "Missing enabled Skip control for Weekly Review step \(index)"
            )
            skip.tap()
        }

        XCTAssertTrue(app.staticTexts["Partial review"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["start-new-weekly-review"].exists)
    }

    func testProjectCompletionIsBlockedWhileOpenActionsRemain() throws {
        relaunchWithProjectAndAreaFixtures()
        openReviewTab()
        app.buttons["start-weekly-review"].tap()

        app.buttons["Projects"].tap()
        app.staticTexts["UI Test Project"].tap()
        let completion = app.buttons["project-completion-action"]
        XCTAssertTrue(completion.waitForExistence(timeout: 5))
        completion.tap()
        XCTAssertTrue(app.alerts["Open actions remain"].waitForExistence(timeout: 5))
    }

    func testProjectCanBeArchivedAndRestoredWithoutLosingLinkedActions() throws {
        relaunchWithProjectAndAreaFixtures()
        app.buttons["Projects"].tap()
        XCTAssertTrue(app.staticTexts["UI Test Project"].waitForExistence(timeout: 10))
        app.staticTexts["UI Test Project"].tap()

        let actionsMenu = app.buttons["project-actions-menu"]
        XCTAssertTrue(actionsMenu.waitForExistence(timeout: 5))
        actionsMenu.tap()
        let archiveAction = app.buttons["archive-project"]
        XCTAssertTrue(archiveAction.waitForExistence(timeout: 5))
        archiveAction.tap()

        let archiveAlert = app.alerts["Archive project?"]
        XCTAssertTrue(archiveAlert.waitForExistence(timeout: 5))
        archiveAlert.buttons["Archive project"].tap()

        app.buttons["Projects"].tap()
        app.buttons["workspace-filter-archived"].tap()
        XCTAssertTrue(app.staticTexts["UI Test Project"].waitForExistence(timeout: 10))
        app.staticTexts["UI Test Project"].tap()
        XCTAssertTrue(app.staticTexts["UI Test Project Next Action"].waitForExistence(timeout: 5))

        app.buttons["project-actions-menu"].tap()
        let restoreAction = app.buttons["restore-project"]
        XCTAssertTrue(restoreAction.waitForExistence(timeout: 5))
        restoreAction.tap()

        app.buttons["Projects"].tap()
        app.buttons["workspace-filter-active"].tap()
        XCTAssertTrue(app.staticTexts["UI Test Project"].waitForExistence(timeout: 10))
    }

    func testEmptyProjectArchiveShowsConfirmation() throws {
        relaunchWithProjectAndAreaFixtures()
        app.buttons["Projects"].tap()
        XCTAssertTrue(app.staticTexts["UI Test Empty Project"].waitForExistence(timeout: 10))
        app.staticTexts["UI Test Empty Project"].tap()

        app.buttons["project-actions-menu"].tap()
        app.buttons["archive-project"].tap()

        let archiveAlert = app.alerts["Archive project?"]
        XCTAssertTrue(archiveAlert.waitForExistence(timeout: 5))
        XCTAssertTrue(archiveAlert.staticTexts["This empty project will be hidden until you restore it."].exists)
        archiveAlert.buttons["Cancel"].tap()
        XCTAssertTrue(app.navigationBars["UI Test Empty Project"].exists)
    }

    func testProjectsSurfaceCanCreateAndOpenAnOutcome() throws {
        relaunchWithProjectAndAreaFixtures()
        let projectsTab = app.buttons["Projects"]
        XCTAssertTrue(projectsTab.waitForExistence(timeout: 15))
        projectsTab.tap()

        XCTAssertTrue(app.staticTexts["OUTCOMES"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Turn multi-step commitments into clear, finishable outcomes."].exists)

        XCTAssertTrue(app.staticTexts["UI Test Project"].waitForExistence(timeout: 5))
        app.staticTexts["UI Test Project"].tap()
        XCTAssertTrue(app.navigationBars["UI Test Project"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Outcome"].exists)
    }

    func testAreasSurfaceCanCreateAndOpenAnOngoingResponsibility() throws {
        relaunchWithProjectAndAreaFixtures()
        openReviewTab()
        XCTAssertTrue(app.buttons["review-areas-overview"].waitForExistence(timeout: 10))
        app.buttons["review-areas-overview"].tap()
        XCTAssertTrue(app.staticTexts["RESPONSIBILITIES"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["UI Test Area"].waitForExistence(timeout: 5))
        app.staticTexts["UI Test Area"].tap()
        XCTAssertTrue(app.navigationBars["UI Test Area"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Responsibility"].exists)
    }

    func testProjectsSurfaceCanSwitchToCompletedFilter() throws {
        app.buttons["Projects"].tap()
        XCTAssertTrue(app.buttons["workspace-filter-active"].waitForExistence(timeout: 10))
        app.buttons["workspace-filter-completed"].tap()
        XCTAssertTrue(app.buttons["workspace-filter-completed"].exists)
    }

    func testProjectDetailShowsOnlyItsLinkedActionsAndProgress() throws {
        relaunchWithProjectAndAreaFixtures()
        app.buttons["Projects"].tap()

        XCTAssertTrue(app.staticTexts["UI Test Project"].waitForExistence(timeout: 10))
        app.staticTexts["UI Test Project"].tap()

        XCTAssertTrue(app.navigationBars["UI Test Project"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["UI Test Project Next Action"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["UI Test Project Completed Action"].exists)
        XCTAssertFalse(app.staticTexts["UI Test Other Area Action"].exists)
        let progress = app.descendants(matching: .any)["project-detail-progress"].firstMatch
        XCTAssertTrue(progress.waitForExistence(timeout: 5))
    }

    func testAreaDetailShowsOnlyItsOpenLinkedActions() throws {
        relaunchWithProjectAndAreaFixtures()
        openReviewTab()
        XCTAssertTrue(app.buttons["review-areas-overview"].waitForExistence(timeout: 10))
        app.buttons["review-areas-overview"].tap()

        XCTAssertTrue(app.staticTexts["UI Test Area"].waitForExistence(timeout: 10))
        app.staticTexts["UI Test Area"].tap()

        XCTAssertTrue(app.navigationBars["UI Test Area"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["UI Test Project Next Action"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["UI Test Project Completed Action"].exists)
        XCTAssertFalse(app.staticTexts["UI Test Other Area Action"].exists)
    }

    func testWorkspaceUsesFiveWorkflowTabsAndFocusPreservesTimerSurface() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10))
        for label in ["Today", "Inbox", "Projects", "Focus", "Review"] {
            XCTAssertTrue(tabBar.buttons[label].exists, "Missing workflow tab: \(label)")
        }
        XCTAssertFalse(tabBar.buttons["Areas"].exists)
        XCTAssertFalse(tabBar.buttons["Profile"].exists)

        tabBar.buttons["Focus"].tap()
        XCTAssertTrue(app.navigationBars["Focus"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.descendants(matching: .any)["CircularTimerView"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["focus-primary-action"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["What deserves your attention?"].exists)
        XCTAssertTrue(app.buttons["focus-current-task"].exists)
    }

    func testFocusOptionsExposeTaskSelectionAndResetWithoutCrowdingTheSurface() throws {
        app.tabBars.buttons["Focus"].tap()

        let options = app.buttons["Focus options"]
        XCTAssertTrue(options.waitForExistence(timeout: 10))
        options.tap()

        XCTAssertTrue(app.buttons["Select task"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Reset timer"].exists)
        XCTAssertFalse(app.buttons["arrow.counterclockwise"].exists)
    }

    func testFocusTaskPickerCanOpenAndDismissWithNoTaskSelected() throws {
        app.tabBars.buttons["Focus"].tap()
        app.buttons["focus-current-task"].tap()

        XCTAssertTrue(app.navigationBars["Select Task"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["No Task"].waitForExistence(timeout: 5))
        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.navigationBars["Focus"].waitForExistence(timeout: 5))
    }
}
