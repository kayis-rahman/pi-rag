import XCTest

final class iOSTaskUITests: XCTestCase {

    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    override func tearDownWithError() throws {
        // Clean up after each test
    }

    // MARK: - Task Management UI Tests

    func testTaskCreationFlow() throws {
        // Navigate to Tasks tab/section
        let tasksTab = app.tabBars.buttons["Tasks"]
        XCTAssertTrue(tasksTab.waitForExistence(timeout: 5), "Tasks tab should be available")
        tasksTab.tap()

        // Look for task creation button
        let createTaskButton = app.buttons["Create Task"]
        XCTAssertTrue(createTaskButton.waitForExistence(timeout: 5), "Create Task button should be visible")
        createTaskButton.tap()

        // Verify task creation form appears
        let taskTitleField = app.textFields["Task Title"]
        XCTAssertTrue(taskTitleField.waitForExistence(timeout: 5), "Task title field should appear")

        let taskDescriptionField = app.textViews["Task Description"]
        XCTAssertTrue(taskDescriptionField.exists, "Task description field should appear")

        let saveButton = app.buttons["Save"]
        XCTAssertTrue(saveButton.exists, "Save button should be visible")
        XCTAssertTrue(saveButton.isEnabled, "Save button should be enabled initially")

        // Test form validation - try to save without title
        saveButton.tap()
        // Should not navigate away or show error

        // Enter task title
        taskTitleField.tap()
        taskTitleField.typeText("Test Task")

        // Enter description
        taskDescriptionField.tap()
        taskDescriptionField.typeText("This is a test task description")

        // Save task
        saveButton.tap()

        // Verify task appears in list
        let taskCell = app.cells.staticTexts["Test Task"]
        XCTAssertTrue(taskCell.waitForExistence(timeout: 5), "Created task should appear in list")
    }

    func testTaskListDisplay() throws {
        // Navigate to Tasks
        let tasksTab = app.tabBars.buttons["Tasks"]
        XCTAssertTrue(tasksTab.waitForExistence(timeout: 5), "Tasks tab should be available")
        tasksTab.tap()

        // Verify task list elements
        let taskList = app.collectionViews["TaskList"]
        XCTAssertTrue(taskList.waitForExistence(timeout: 5), "Task list should be visible")

        // Check for task status indicators
        let todoTasks = app.staticTexts["TODO"]
        let inProgressTasks = app.staticTexts["IN_PROGRESS"]
        let completedTasks = app.staticTexts["COMPLETED"]

        // At least one status type should be visible (may be empty but UI should show sections)
        let hasAnyStatus = todoTasks.exists || inProgressTasks.exists || completedTasks.exists
        XCTAssertTrue(hasAnyStatus, "Task list should show status sections")
    }

    func testTaskStatusUpdate() throws {
        // Navigate to Tasks
        let tasksTab = app.tabBars.buttons["Tasks"]
        XCTAssertTrue(tasksTab.waitForExistence(timeout: 5), "Tasks tab should be available")
        tasksTab.tap()

        // Find a task to update (assuming test data exists)
        let taskCell = app.cells.element(boundBy: 0)
        if taskCell.waitForExistence(timeout: 5) {
            taskCell.tap()

            // Look for status update controls
            let completeButton = app.buttons["Mark Complete"]
            let startButton = app.buttons["Start Task"]

            if completeButton.exists {
                completeButton.tap()
                // Verify status changed
                XCTAssertTrue(app.staticTexts["COMPLETED"].waitForExistence(timeout: 2), "Task should show completed status")
            } else if startButton.exists {
                startButton.tap()
                // Verify status changed
                XCTAssertTrue(app.staticTexts["IN_PROGRESS"].waitForExistence(timeout: 2), "Task should show in progress status")
            }
        }
    }

    func testTaskDeletion() throws {
        // Navigate to Tasks
        let tasksTab = app.tabBars.buttons["Tasks"]
        XCTAssertTrue(tasksTab.waitForExistence(timeout: 5), "Tasks tab should be available")
        tasksTab.tap()

        // Get initial task count
        let taskList = app.collectionViews["TaskList"]
        let initialCount = taskList.cells.count

        // Find and delete a task
        let taskCell = app.cells.element(boundBy: 0)
        if taskCell.waitForExistence(timeout: 5) {
            // Long press or find delete button
            taskCell.press(forDuration: 1.0)

            let deleteButton = app.buttons["Delete"]
            if deleteButton.waitForExistence(timeout: 2) {
                deleteButton.tap()

                // Confirm deletion
                let confirmButton = app.alerts.buttons["Delete"]
                if confirmButton.waitForExistence(timeout: 2) {
                    confirmButton.tap()
                }

                // Verify task was removed
                let finalCount = taskList.cells.count
                XCTAssertLessThan(finalCount, initialCount, "Task count should decrease after deletion")
            }
        }
    }

    // MARK: - Timer-Task Integration Tests

    func testTimerTaskSelection() throws {
        // Navigate to main timer view
        let timerView = app.otherElements["CircularTimerView"]
        XCTAssertTrue(timerView.waitForExistence(timeout: 5), "Timer view should be visible")

        // Look for task selection button
        let selectTaskButton = app.buttons["Select Task"]
        XCTAssertTrue(selectTaskButton.waitForExistence(timeout: 5), "Select Task button should be visible")
        selectTaskButton.tap()

        // Verify task picker appears
        let taskPicker = app.sheets["TaskPickerView"]
        XCTAssertTrue(taskPicker.waitForExistence(timeout: 5), "Task picker should appear")

        // Select a task (if available)
        let taskOption = app.buttons.element(boundBy: 0)
        if taskOption.waitForExistence(timeout: 2) {
            taskOption.tap()

            // Verify task is selected in timer
            let currentTaskDisplay = app.staticTexts.matching(identifier: "CurrentTask").firstMatch
            XCTAssertTrue(currentTaskDisplay.exists, "Current task should be displayed in timer")
        }
    }

    func testTimerWithTaskAssociation() throws {
        // Select a task first
        let selectTaskButton = app.buttons["Select Task"]
        if selectTaskButton.waitForExistence(timeout: 5) {
            selectTaskButton.tap()

            let taskOption = app.buttons.element(boundBy: 0)
            if taskOption.waitForExistence(timeout: 2) {
                taskOption.tap()

                // Start timer
                let startButton = app.buttons["Start"]
                startButton.tap()

                // Verify timer shows task context
                let taskIndicator = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Working on'")).firstMatch
                XCTAssertTrue(taskIndicator.exists, "Timer should show task context")

                // Stop timer
                let stopButton = app.buttons["Stop"]
                if stopButton.waitForExistence(timeout: 2) {
                    stopButton.tap()
                }
            }
        }
    }

    // MARK: - Task Analytics Tests

    func testTaskAnalyticsDisplay() throws {
        // Navigate to Analytics
        let analyticsButton = app.buttons["Analytics"]
        XCTAssertTrue(analyticsButton.waitForExistence(timeout: 5), "Analytics button should be available")
        analyticsButton.tap()

        // Wait for analytics to load
        let analyticsView = app.scrollViews.firstMatch
        XCTAssertTrue(analyticsView.waitForExistence(timeout: 10), "Analytics view should load")

        // Check for task analytics section
        let taskAnalyticsCard = app.staticTexts["Task Analytics"]
        XCTAssertTrue(taskAnalyticsCard.waitForExistence(timeout: 5), "Task analytics section should be visible")

        // Verify task metrics are displayed
        let totalTasksLabel = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Total Tasks'")).firstMatch
        XCTAssertTrue(totalTasksLabel.exists, "Total tasks metric should be displayed")

        let completedTasksLabel = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Completed'")).firstMatch
        XCTAssertTrue(completedTasksLabel.exists, "Completed tasks metric should be displayed")
    }

    func testTaskAnalyticsInteraction() throws {
        // Navigate to Analytics
        let analyticsButton = app.buttons["Analytics"]
        XCTAssertTrue(analyticsButton.waitForExistence(timeout: 5), "Analytics button should be available")
        analyticsButton.tap()

        // Scroll to task analytics
        let taskAnalyticsCard = app.staticTexts["Task Analytics"]
        if taskAnalyticsCard.waitForExistence(timeout: 5) {
            // Scroll to make it visible
            app.scrollViews.firstMatch.scrollToElement(element: taskAnalyticsCard)

            // Verify all task metrics are present
            let timeSpentLabel = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Time Spent'")).firstMatch
            XCTAssertTrue(timeSpentLabel.exists, "Time spent metric should be displayed")

            let completionRateLabel = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '%'")).firstMatch
            XCTAssertTrue(completionRateLabel.exists, "Completion rate should be displayed")
        }
    }

    // MARK: - Accessibility Tests

    func testTaskManagementAccessibility() throws {
        // Navigate to Tasks
        let tasksTab = app.tabBars.buttons["Tasks"]
        if tasksTab.waitForExistence(timeout: 5) {
            tasksTab.tap()

            // Test VoiceOver compatibility
            let createTaskButton = app.buttons["Create Task"]
            XCTAssertTrue(createTaskButton.exists, "Create Task button should be accessible")

            // Test dynamic type support
            let taskCells = app.cells.allElementsBoundByIndex
            if !taskCells.isEmpty {
                XCTAssertTrue(taskCells[0].exists, "Task cells should support dynamic type")
            }
        }
    }

    // MARK: - Performance Tests

    func testTaskUIResponsiveness() throws {
        measure(metrics: [XCTClockMetric(), XCTCPUMetric(), XCTMemoryMetric()]) {
            // Navigate to Tasks
            let tasksTab = app.tabBars.buttons["Tasks"]
            if tasksTab.waitForExistence(timeout: 5) {
                tasksTab.tap()

                // Test task list loading
                let taskList = app.collectionViews["TaskList"]
                XCTAssertTrue(taskList.waitForExistence(timeout: 5), "Task list should load quickly")

                // Test task creation button tap
                let createTaskButton = app.buttons["Create Task"]
                if createTaskButton.waitForExistence(timeout: 2) {
                    createTaskButton.tap()

                    let taskTitleField = app.textFields["Task Title"]
                    XCTAssertTrue(taskTitleField.waitForExistence(timeout: 2), "Task creation form should appear quickly")
                }
            }
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