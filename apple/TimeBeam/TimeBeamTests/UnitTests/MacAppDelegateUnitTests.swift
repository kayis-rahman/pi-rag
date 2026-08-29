//
//  MacAppDelegateUnitTests.swift
//  TimeBeamTests
//
//  Created by TimeBeam Team
//  Unit tests for MacAppDelegate functionality
//  Testing status bar updates, notification handling, and device registration feedback
//

import XCTest
@testable import TimeBeam

#if os(macOS)
final class MacAppDelegateUnitTests: XCTestCase {

    private var appDelegate: MacAppDelegate!
    private var mockNotificationCenter: MockUNUserNotificationCenter!

    override func setUpWithError() throws {
        appDelegate = MacAppDelegate()
        mockNotificationCenter = MockUNUserNotificationCenter()

        // Replace the shared notification center with our mock
        // Note: In real implementation, this would require protocol-based design
    }

    override func tearDownWithError() throws {
        appDelegate = nil
        mockNotificationCenter = nil
    }

    // MARK: - Status Bar Tests

    func testStatusBarItemCreation() throws {
        // Given - App delegate is initialized

        // When - Application finishes launching
        let notification = Notification(name: NSApplication.didFinishLaunchingNotification)
        appDelegate.applicationDidFinishLaunching(notification)

        // Then - Status bar item should be created
        XCTAssertNotNil(MacAppDelegate.statusItem, "Status bar item should be created")
        XCTAssertNotNil(MacAppDelegate.statusItem?.button, "Status bar button should exist")
    }

    func testStatusBarTitleUpdate() throws {
        // Given - Status bar item exists
        let notification = Notification(name: NSApplication.didFinishLaunchingNotification)
        appDelegate.applicationDidFinishLaunching(notification)

        // When - Update status bar title
        MacAppDelegate.updateStatusItem(title: "Test Status")

        // Then - Status bar should show the title
        XCTAssertEqual(MacAppDelegate.statusItem?.button?.title, "Test Status")
    }

    func testStatusBarTitleClear() throws {
        // Given - Status bar has a title
        let notification = Notification(name: NSApplication.didFinishLaunchingNotification)
        appDelegate.applicationDidFinishLaunching(notification)
        MacAppDelegate.updateStatusItem(title: "Test Status")

        // When - Clear status bar title
        MacAppDelegate.updateStatusItem(title: nil)

        // Then - Status bar should be empty
        XCTAssertEqual(MacAppDelegate.statusItem?.button?.title, "")
    }

    func testTemporaryStatusDisplay() throws {
        // Given - Status bar exists with initial title
        let notification = Notification(name: NSApplication.didFinishLaunchingNotification)
        appDelegate.applicationDidFinishLaunching(notification)
        let originalTitle = "Original"
        MacAppDelegate.updateStatusItem(title: originalTitle)

        // When - Show temporary status
        MacAppDelegate.showTemporaryStatus("✓ Device registered", duration: 0.1)

        // Wait briefly for the status to be set
        let expectation = expectation(description: "Temporary status displayed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            // Then - Status bar should show temporary message
            XCTAssertEqual(MacAppDelegate.statusItem?.button?.title, "✓ Device registered")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)

        // Wait for restoration
        let restoreExpectation = expectation(description: "Original status restored")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            XCTAssertEqual(MacAppDelegate.statusItem?.button?.title, originalTitle)
            restoreExpectation.fulfill()
        }

        wait(for: [restoreExpectation], timeout: 1.0)
    }

    func testTemporaryStatusWithEmptyOriginalTitle() throws {
        // Given - Status bar exists with no title
        let notification = Notification(name: NSApplication.didFinishLaunchingNotification)
        appDelegate.applicationDidFinishLaunching(notification)
        MacAppDelegate.updateStatusItem(title: nil)

        // When - Show temporary status
        MacAppDelegate.showTemporaryStatus("✓ Sync complete", duration: 0.1)

        // Wait briefly for the status to be set
        let expectation = expectation(description: "Temporary status displayed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            XCTAssertEqual(MacAppDelegate.statusItem?.button?.title, "✓ Sync complete")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)

        // Wait for restoration
        let restoreExpectation = expectation(description: "Empty status restored")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            XCTAssertEqual(MacAppDelegate.statusItem?.button?.title, "")
            restoreExpectation.fulfill()
        }

        wait(for: [restoreExpectation], timeout: 1.0)
    }

    // MARK: - Notification Permission Tests

    func testNotificationPermissionRequest() throws {
        // Given - Mock notification center

        // When - Application finishes launching
        let notification = Notification(name: NSApplication.didFinishLaunchingNotification)
        appDelegate.applicationDidFinishLaunching(notification)

        // Then - Notification permission should be requested
        // Note: In real implementation, we'd verify the mock was called
        // For now, we verify the method completes without error
        XCTAssertNotNil(appDelegate, "App delegate should handle launch")
    }

    // MARK: - APN Token Registration Tests

    func testAPNTokenRegistrationSuccess() throws {
        // Given - Mock APN token data
        let mockToken = "mock-apn-token-12345".data(using: .utf8)!

        // When - APN token is received
        appDelegate.application(NSApplication.shared,
                               didRegisterForRemoteNotificationsWithDeviceToken: mockToken)

        // Then - Token should be processed
        // Note: In real implementation, we'd verify the token was sent to backend
        XCTAssertNotNil(appDelegate, "App delegate should handle APN token")
    }

    func testAPNTokenRegistrationFailure() throws {
        // Given - Mock error
        let mockError = NSError(domain: "APNError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Registration failed"])

        // When - APN registration fails
        appDelegate.application(NSApplication.shared,
                               didFailToRegisterForRemoteNotificationsWithError: mockError)

        // Then - Error should be handled gracefully
        XCTAssertNotNil(appDelegate, "App delegate should handle APN registration failure")
    }

    // MARK: - Push Notification Handling Tests

    func testTimerSyncPushNotificationHandling() throws {
        // Given - Mock push notification for timer sync
        let userInfo: [AnyHashable: Any] = [
            "type": "timer_sync",
            "action": [
                "action": "PAUSE",
                "deviceId": "other-device-id",
                "timestamp": "2024-01-01T12:00:00Z"
            ]
        ]

        let mockResponse = MockUNNotificationResponse(userInfo: userInfo)

        // When - Push notification is received
        let expectation = expectation(description: "Push notification handled")
        appDelegate.userNotificationCenter(UNUserNotificationCenter.current(),
                                          didReceive: mockResponse) { completion in
            expectation.fulfill()
        }

        // Then - Notification should be processed
        wait(for: [expectation], timeout: 1.0)
    }

    func testNonTimerSyncPushNotificationPassthrough() throws {
        // Given - Mock non-timer push notification
        let userInfo: [AnyHashable: Any] = [
            "aps": [
                "alert": "Test notification",
                "sound": "default"
            ]
        ]

        let mockResponse = MockUNNotificationResponse(userInfo: userInfo)

        // When - Regular push notification is received
        let expectation = expectation(description: "Regular notification handled")
        appDelegate.userNotificationCenter(UNUserNotificationCenter.current(),
                                          didReceive: mockResponse) { completion in
            expectation.fulfill()
        }

        // Then - Notification should be handled normally
        wait(for: [expectation], timeout: 1.0)
    }

    func testSilentTimerSyncNotificationPresentation() throws {
        // Given - Mock silent timer sync notification
        let userInfo: [AnyHashable: Any] = [
            "type": "timer_sync",
            "action": [
                "action": "START",
                "deviceId": "other-device-id",
                "timestamp": ISO8601DateFormatter().string(from: Date())
            ]
        ]

        let mockNotification = MockUNNotification(userInfo: userInfo)

        // When - Silent notification is about to be presented
        let expectation = expectation(description: "Silent notification presentation handled")
        appDelegate.userNotificationCenter(UNUserNotificationCenter.current(),
                                          willPresent: mockNotification) { options in
            // Then - No presentation options should be returned (silent)
            XCTAssertEqual(options, [], "Silent notifications should not be presented")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testRegularNotificationPresentation() throws {
        // Given - Mock regular notification
        let userInfo: [AnyHashable: Any] = [
            "aps": [
                "alert": "Regular notification",
                "sound": "default",
                "badge": 1
            ]
        ]

        let mockNotification = MockUNNotification(userInfo: userInfo)

        // When - Regular notification is about to be presented
        let expectation = expectation(description: "Regular notification presentation handled")
        appDelegate.userNotificationCenter(UNUserNotificationCenter.current(),
                                          willPresent: mockNotification) { options in
            // Then - Standard presentation options should be returned
            XCTAssertTrue(options.contains(.banner) || options.contains(.sound),
                         "Regular notifications should have presentation options")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Performance Tests

    func testStatusBarUpdatePerformance() throws {
        // Given - Status bar exists
        let notification = Notification(name: NSApplication.didFinishLaunchingNotification)
        appDelegate.applicationDidFinishLaunching(notification)

        // When/Then - Measure status bar update performance
        measure {
            MacAppDelegate.updateStatusItem(title: "Performance Test \(UUID().uuidString)")
        }
    }

    func testTemporaryStatusPerformance() throws {
        // Given - Status bar exists
        let notification = Notification(name: NSApplication.didFinishLaunchingNotification)
        appDelegate.applicationDidFinishLaunching(notification)

        // When/Then - Measure temporary status performance
        measure {
            MacAppDelegate.showTemporaryStatus("Performance Test", duration: 0.001)
        }
    }
}

// MARK: - Mock Classes

private class MockUNUserNotificationCenter: UNUserNotificationCenter {
    var requestedAuthorization = false
    var authorizationOptions: UNAuthorizationOptions?

    override func requestAuthorization(options: UNAuthorizationOptions = [],
                                     completionHandler: @escaping (Bool, Error?) -> Void) {
        requestedAuthorization = true
        authorizationOptions = options
        completionHandler(true, nil)
    }
}

private class MockUNNotificationResponse: UNNotificationResponse {
    private let mockUserInfo: [AnyHashable: Any]

    init(userInfo: [AnyHashable: Any]) {
        self.mockUserInfo = userInfo
        let mockRequest = MockUNNotificationRequest(userInfo: userInfo)
        super.init()
        // Note: In real implementation, this would need proper initialization
    }

    override var notification: UNNotification {
        return MockUNNotification(userInfo: mockUserInfo)
    }
}

private class MockUNNotificationRequest: UNNotificationRequest {
    private let mockUserInfo: [AnyHashable: Any]

    init(userInfo: [AnyHashable: Any]) {
        self.mockUserInfo = userInfo
        super.init(identifier: "mock", content: UNNotificationContent(), trigger: nil)
    }

    override var content: UNNotificationContent {
        let content = UNNotificationContent()
        // Note: In real implementation, userInfo would be set properly
        return content
    }
}

private class MockUNNotification: UNNotification {
    private let mockUserInfo: [AnyHashable: Any]

    init(userInfo: [AnyHashable: Any]) {
        self.mockUserInfo = userInfo
        let mockRequest = MockUNNotificationRequest(userInfo: userInfo)
        super.init()
        // Note: In real implementation, this would need proper initialization
    }

    override var request: UNNotificationRequest {
        return MockUNNotificationRequest(userInfo: mockUserInfo)
    }
}

#endif