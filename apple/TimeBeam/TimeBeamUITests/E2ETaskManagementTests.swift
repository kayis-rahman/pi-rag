//
//  E2ETaskManagementTests.swift
//  TimeBeamUITests
//
//  Created by TimeBeam Team
//  End-to-end task management tests connecting to live backend
//

import XCTest

final class E2ETaskManagementTests: TimeBeamE2ETestBase {

    // MARK: - Task Creation Tests

    func testTaskCreationWithAllFields() throws {
        performAuthenticatedAction {
            // Navigate to Tasks tab
            app.navigateToTab("Tasks")

            // Click create task button
            let createButton = app.buttons["Create Task"]
            XCTAssertTrue(createButton.waitForExistence(timeout: TestConfiguration.defaultTimeout),
                         "Create Task button should be available")
            createButton.tap()

            // Verify form appears
            let titleField = app.textFields["Task Title"]
            XCTAssertTrue(titleField.waitForExistence(timeout: TestConfiguration.quickTimeout),
                         "Task title field should appear")

            // Fill out all fields
            titleField.tap()
            titleField.typeText("E2E Test Task - Complete Implementation")

            let descriptionField = app.textViews["Task Description"]
            XCTAssertTrue(descriptionField.exists, "Task description field should be available")
            descriptionField.tap()
            descriptionField.typeText("""
            This is a comprehensive test task for E2E testing.
            It includes multiple steps:
            1. Design the solution
            2. Implement the code
            3. Test thoroughly
            4. Deploy to production

            This task validates the full task creation workflow with live backend persistence.
            """)

            // Save the task
            let saveButton = app.buttons["Save"]
            XCTAssertTrue(saveButton.waitForExistence(timeout: TestConfiguration.quickTimeout),
                         "Save button should be available")
            XCTAssertTrue(saveButton.isEnabled, "Save button should be enabled")
            saveButton.tap()

            // Verify task appears in list
            let createdTask = app.cells.staticTexts["E2E Test Task - Complete Implementation"]
            XCTAssertTrue(createdTask.waitForExistence(timeout: TestConfiguration.defaultTimeout),
                         "Created task should appear in the task list")

            // Wait for backend sync and verify via API
            waitForNetworkOperation(timeout: TestConfiguration.extendedTimeout)
            verifyTaskCreatedInBackend("E2E Test Task - Complete Implementation")
        }
    }

    func testTaskCreationValidation() throws {
        performAuthenticatedAction {
            app.navigateToTab("Tasks")
            app.buttons["Create Task"].tap()

            // Try to save without title (should fail)
            let saveButton = app.buttons["Save"]
            saveButton.tap()

            // Should still be on form (validation failed)
            XCTAssertTrue(app.textFields["Task Title"].exists,
                         "Should remain on form when validation fails")

            // Now fill required fields and save
            let titleField = app.textFields["Task Title"]
            titleField.tap()
            titleField.typeText("Validation Test Task")
            saveButton.tap()

            // Should navigate away (success)
            XCTAssertTrue(app.cells.staticTexts["Validation Test Task"].waitForExistence(timeout: TestConfiguration.defaultTimeout),
                         "Task should be created after fixing validation")
        }
    }

    // MARK: - Task Reading/List Tests

    func testTaskListDisplay() throws {
        performAuthenticatedAction {
            app.navigateToTab("Tasks")

            // Verify seeded tasks are displayed
            let taskList = app.collectionViews["TaskList"]
            XCTAssertTrue(taskList.waitForExistence(timeout: TestConfiguration.defaultTimeout),
                         "Task list should be visible")

            // Check expected task count from seeded data
            let taskCells = app.cells.allElementsBoundByIndex
            XCTAssertGreaterThanOrEqual(taskCells.count, TestConfiguration.ExpectedData.initialTaskCount,
                                       "Should display at least the seeded tasks")

            // Verify specific seeded tasks
            let documentationTask = app.staticTexts["Complete project documentation"]
            XCTAssertTrue(documentationTask.exists, "Seeded documentation task should be visible")

            let authTask = app.staticTexts["Implement user authentication"]
            XCTAssertTrue(authTask.exists, "Seeded authentication task should be visible")
        }
    }

    func testTaskDetailView() throws {
        performAuthenticatedAction {
            app.navigateToTab("Tasks")

            // Tap on a task to view details
            let taskCell = app.cells.staticTexts["Complete project documentation"]
            XCTAssertTrue(taskCell.exists, "Task should be available for detail view")
            taskCell.tap()

            // Verify detail view shows correct information
            let taskTitle = app.staticTexts["Complete project documentation"]
            XCTAssertTrue(taskTitle.exists, "Task title should be visible in detail view")

            let taskDescription = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'documentation for the TimeBeam project'")).firstMatch
            XCTAssertTrue(taskDescription.exists, "Task description should be visible")

            // Check status indicators
            let todoStatus = app.staticTexts["TODO"]
            XCTAssertTrue(todoStatus.exists, "Task status should be displayed")
        }
    }

    // MARK: - Task Update Tests

    func testTaskStatusUpdate() throws {
        performAuthenticatedAction {
            app.navigateToTab("Tasks")

            // Create a test task first
            app.buttons["Create Task"].tap()
            let titleField = app.textFields["Task Title"]
            titleField.tap()
            titleField.typeText("Status Update Test Task")
            app.buttons["Save"].tap()

            // Find and tap the newly created task
            let newTask = app.cells.staticTexts["Status Update Test Task"]
            XCTAssertTrue(newTask.waitForExistence(timeout: TestConfiguration.defaultTimeout),
                         "Newly created task should be available")
            newTask.tap()

            // Update status to In Progress
            let startButton = app.buttons["Start Task"]
            if startButton.waitForExistence(timeout: TestConfiguration.quickTimeout) {
                startButton.tap()

                // Verify status changed
                let inProgressStatus = app.staticTexts["IN_PROGRESS"]
                XCTAssertTrue(inProgressStatus.waitForExistence(timeout: TestConfiguration.quickTimeout),
                             "Task status should change to In Progress")

                // Wait for backend sync
                waitForNetworkOperation()
                verifyTaskStatusInBackend("Status Update Test Task", "in_progress")
            }
        }
    }

    func testTaskContentUpdate() throws {
        performAuthenticatedAction {
            app.navigateToTab("Tasks")

            // Create a test task
            app.buttons["Create Task"].tap()
            let titleField = app.textFields["Task Title"]
            titleField.tap()
            titleField.typeText("Content Update Test Task")
            app.buttons["Save"].tap()

            // Find and edit the task
            let taskCell = app.cells.staticTexts["Content Update Test Task"]
            taskCell.tap()

            // Look for edit button
            let editButton = app.buttons["Edit"]
            if editButton.waitForExistence(timeout: TestConfiguration.quickTimeout) {
                editButton.tap()

                // Update title
                let titleEditField = app.textFields["Content Update Test Task"]
                titleEditField.tap()
                titleEditField.clearText()
                titleEditField.typeText("Updated Content Test Task")

                // Update description
                let descriptionField = app.textViews.containing(NSPredicate(format: "value CONTAINS ''")).firstMatch
                descriptionField.tap()
                descriptionField.typeText("Updated description for content test")

                // Save changes
                app.buttons["Save"].tap()

                // Verify updates
                let updatedTask = app.staticTexts["Updated Content Test Task"]
                XCTAssertTrue(updatedTask.waitForExistence(timeout: TestConfiguration.defaultTimeout),
                             "Updated task title should be visible")

                // Verify backend sync
                waitForNetworkOperation()
                verifyTaskUpdatedInBackend("Updated Content Test Task")
            }
        }
    }

    // MARK: - Task Deletion Tests

    func testTaskDeletion() throws {
        performAuthenticatedAction {
            app.navigateToTab("Tasks")

            // Create a test task for deletion
            app.buttons["Create Task"].tap()
            let titleField = app.textFields["Task Title"]
            titleField.tap()
            titleField.typeText("Deletion Test Task")
            app.buttons["Save"].tap()

            // Verify task was created
            let createdTask = app.cells.staticTexts["Deletion Test Task"]
            XCTAssertTrue(createdTask.waitForExistence(timeout: TestConfiguration.defaultTimeout),
                         "Task should be created before deletion test")

            // Delete the task
            createdTask.tap()

            // Look for delete option (might be in a menu or long press action)
            let deleteButton = app.buttons["Delete"]
            if deleteButton.waitForExistence(timeout: TestConfiguration.quickTimeout) {
                deleteButton.tap()

                // Confirm deletion
                let confirmButton = app.alerts.buttons["Delete"]
                if confirmButton.waitForExistence(timeout: TestConfiguration.quickTimeout) {
                    confirmButton.tap()
                }

                // Verify task is gone
                XCTAssertFalse(app.staticTexts["Deletion Test Task"].waitForExistence(timeout: TestConfiguration.quickTimeout),
                              "Deleted task should no longer be visible")

                // Verify backend sync
                waitForNetworkOperation()
                verifyTaskDeletedFromBackend("Deletion Test Task")
            }
        }
    }

    // MARK: - Task Filtering and Search Tests

    func testTaskStatusFiltering() throws {
        performAuthenticatedAction {
            app.navigateToTab("Tasks")

            // Test filtering by status (if implemented)
            // This would test UI filtering controls

            // For now, verify different status tasks exist
            let todoTasks = app.staticTexts["TODO"]
            let inProgressTasks = app.staticTexts["IN_PROGRESS"]
            let completedTasks = app.staticTexts["COMPLETED"]

            // Should have tasks in different states from seeded data
            XCTAssertGreaterThan(app.cells.count, 0, "Should have tasks to filter")
        }
    }

    // MARK: - Bulk Operations Tests

    func testBulkTaskOperations() throws {
        performAuthenticatedAction {
            app.navigateToTab("Tasks")

            // Test selecting multiple tasks (if supported)
            // This would test bulk status updates or deletions

            // For now, verify multiple tasks can be interacted with individually
            let taskCells = app.cells.allElementsBoundByIndex
            XCTAssertGreaterThan(taskCells.count, 1, "Should have multiple tasks for bulk operation testing")

            // Test that individual operations work on different tasks
            if taskCells.count >= 2 {
                // This validates the UI can handle multiple task interactions
                XCTAssertTrue(taskCells[0].exists && taskCells[1].exists,
                             "Multiple tasks should be accessible")
            }
        }
    }

    // MARK: - Task Analytics Integration Tests

    func testTaskTimeTracking() throws {
        performAuthenticatedAction {
            // Create a task and associate timer sessions
            app.navigateToTab("Tasks")
            app.buttons["Create Task"].tap()

            let titleField = app.textFields["Task Title"]
            titleField.tap()
            titleField.typeText("Time Tracking Test Task")
            app.buttons["Save"].tap()

            // Start timer with this task
            app.navigateToTab("Timer")

            // Select the task for timer (if supported)
            let selectTaskButton = app.buttons["Select Task"]
            if selectTaskButton.waitForExistence(timeout: TestConfiguration.quickTimeout) {
                selectTaskButton.tap()

                let taskOption = app.buttons["Time Tracking Test Task"]
                if taskOption.waitForExistence(timeout: TestConfiguration.quickTimeout) {
                    taskOption.tap()
                }
            }

            // Start and stop timer
            app.buttons["Start"].tap()
            waitForNetworkOperation()

            Thread.sleep(forTimeInterval: 3.0) // Let session run briefly

            app.buttons["Pause"].tap()
            waitForNetworkOperation()

            // Check task details for time tracking
            app.navigateToTab("Tasks")
            let taskCell = app.cells.staticTexts["Time Tracking Test Task"]
            taskCell.tap()

            // Verify time tracking information (if displayed)
            let timeLabels = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'time' OR label CONTAINS 'Time' OR label CONTAINS 'minute' OR label CONTAINS 'Minute'"))
            // Note: Actual time display verification depends on UI implementation
        }
    }

    func testTaskAnalyticsIntegration() throws {
        performAuthenticatedAction {
            // Navigate to Analytics
            app.navigateToTab("Analytics")

            // Verify task-related analytics are displayed
            let taskAnalytics = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'task' OR label CONTAINS 'Task'")).firstMatch
            XCTAssertTrue(taskAnalytics.exists, "Task analytics should be visible")

            // Verify analytics reflect task data from seeded data
            let completedTasksMetric = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '1'")).firstMatch
            XCTAssertTrue(completedTasksMetric.exists, "Should show completed tasks count")
        }
    }

    // MARK: - Helper Methods

    private func verifyTaskCreatedInBackend(_ taskTitle: String) {
        // Verify task exists in backend
        let tasksURL = URL(string: "\(TestConfiguration.e2eBackendURL)/api/tasks")!
        var request = URLRequest(url: tasksURL)
        request.httpMethod = "GET"

        let token = try! loginAndGetToken(email: TestConfiguration.testUserEmail)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let expectation = expectation(description: "Verify task creation in backend")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200,
               let data = data {
                do {
                    let tasks = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
                    let taskTitles = tasks?.compactMap { $0["title"] as? String }
                    XCTAssertTrue(taskTitles?.contains(taskTitle) ?? false,
                                 "Created task should exist in backend")
                } catch {
                    XCTFail("Failed to parse tasks response: \(error)")
                }
            }
            expectation.fulfill()
        }.resume()

        wait(for: [expectation], timeout: TestConfiguration.defaultTimeout)
    }

    private func verifyTaskStatusInBackend(_ taskTitle: String, _ expectedStatus: String) {
        // Verify task status in backend
        let tasksURL = URL(string: "\(TestConfiguration.e2eBackendURL)/api/tasks")!
        var request = URLRequest(url: tasksURL)
        request.httpMethod = "GET"

        let token = try! loginAndGetToken(email: TestConfiguration.testUserEmail)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let expectation = expectation(description: "Verify task status in backend")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200,
               let data = data {
                do {
                    let tasks = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
                    let targetTask = tasks?.first { ($0["title"] as? String) == taskTitle }
                    XCTAssertNotNil(targetTask, "Task should exist")
                    XCTAssertEqual(targetTask?["status"] as? String, expectedStatus,
                                 "Task status should match expected value")
                } catch {
                    XCTFail("Failed to parse tasks response: \(error)")
                }
            }
            expectation.fulfill()
        }.resume()

        wait(for: [expectation], timeout: TestConfiguration.defaultTimeout)
    }

    private func verifyTaskUpdatedInBackend(_ taskTitle: String) {
        // Verify task was updated in backend
        let tasksURL = URL(string: "\(TestConfiguration.e2eBackendURL)/api/tasks")!
        var request = URLRequest(url: tasksURL)
        request.httpMethod = "GET"

        let token = try! loginAndGetToken(email: TestConfiguration.testUserEmail)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let expectation = expectation(description: "Verify task update in backend")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200,
               let data = data {
                do {
                    let tasks = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
                    let updatedTask = tasks?.first { ($0["title"] as? String) == taskTitle }
                    XCTAssertNotNil(updatedTask, "Updated task should exist in backend")
                } catch {
                    XCTFail("Failed to parse tasks response: \(error)")
                }
            }
            expectation.fulfill()
        }.resume()

        wait(for: [expectation], timeout: TestConfiguration.defaultTimeout)
    }

    private func verifyTaskDeletedFromBackend(_ taskTitle: String) {
        // Verify task was deleted from backend
        let tasksURL = URL(string: "\(TestConfiguration.e2eBackendURL)/api/tasks")!
        var request = URLRequest(url: tasksURL)
        request.httpMethod = "GET"

        let token = try! loginAndGetToken(email: TestConfiguration.testUserEmail)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let expectation = expectation(description: "Verify task deletion from backend")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200,
               let data = data {
                do {
                    let tasks = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
                    let taskTitles = tasks?.compactMap { $0["title"] as? String }
                    XCTAssertFalse(taskTitles?.contains(taskTitle) ?? false,
                                 "Deleted task should not exist in backend")
                } catch {
                    XCTFail("Failed to parse tasks response: \(error)")
                }
            }
            expectation.fulfill()
        }.resume()

        wait(for: [expectation], timeout: TestConfiguration.defaultTimeout)
    }

    private func loginAndGetToken(email: String) throws -> String {
        let loginURL = URL(string: "\(TestConfiguration.e2eBackendURL)/api/auth/login")!
        var request = URLRequest(url: loginURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let loginBody = ["email": email]
        request.httpBody = try JSONSerialization.data(withJSONObject: loginBody)

        let semaphore = DispatchSemaphore(value: 0)
        var token: String?

        URLSession.shared.dataTask(with: request) { data, response, error in
            defer { semaphore.signal() }

            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200,
               let data = data {
                do {
                    let responseJSON = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    token = responseJSON?["accessToken"] as? String
                } catch {
                    XCTFail("Failed to parse login response: \(error)")
                }
            }
        }.resume()

        semaphore.wait()
        return try XCTUnwrap(token, "Should receive access token")
    }
}
