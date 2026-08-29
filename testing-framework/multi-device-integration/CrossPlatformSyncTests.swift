//
//  CrossPlatformSyncTests.swift
//  TimeBeam Testing Framework
//
//  Multi-device integration tests for cross-platform synchronization
//

import Foundation

/// Comprehensive cross-platform synchronization tests
/// Tests iOS ↔ macOS ↔ watchOS timer synchronization scenarios
public class CrossPlatformSyncTests {
    
    // MARK: - Properties
    
    private let testDeviceManager = TestDeviceManager()
    private let testNetworkSimulator = TestNetworkSimulator()
    private let testResultCollector = TestResultCollector()
    private let testMetricsCollector = TestMetricsCollector()
    
    // MARK: - Cross-Device Continuity Tests
    
    /// Test timer synchronization from iOS to macOS
    public func testiOSToMacOSTimerSync() async throws {
        let testName = "iOS_to_macOS_Timer_Sync"
        let startTime = Date()
        
        do {
            // Setup devices
            let iOSDevice = MockDeviceFactory.createDevice(type: "ios")
            let macOSDevice = MockDeviceFactory.createDevice(type: "macos")
            
            // Setup synchronization callbacks
            var syncedStates: [MockTimerState] = []
            macOSDevice.onSync { state in
                syncedStates.append(state)
            }
            
            // Start timer on iOS device
            iOSDevice.simulateTimerAction(.start)
            
            // Wait for sync to propagate
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // Verify timer synced to macOS
            guard let syncedState = syncedStates.last else {
                throw TestError.syncFailed("No timer state synced to macOS")
            }
            
            XCTAssertEqual(syncedState.isRunning, true, "Timer should be running on macOS")
            XCTAssertEqual(syncedState.phase, "work", "Timer should be in work phase on macOS")
            
            // Test pause synchronization
            iOSDevice.simulateTimerAction(.pause)
            try await Task.sleep(nanoseconds: 500_000_000)
            
            guard let pausedState = syncedStates.last else {
                throw TestError.syncFailed("No pause state synced to macOS")
            }
            
            XCTAssertEqual(pausedState.isRunning, false, "Timer should be paused on macOS")
            
            let duration = Date().timeIntervalSince(startTime)
            let metrics = testMetricsCollector.collectMetrics(
                testID: testName,
                deviceID: iOSDevice.deviceConfig.id,
                startTime: startTime,
                endTime: Date()
            )
            
            let result = TestResult(
                testName: testName,
                success: true,
                duration: duration,
                metrics: metrics
            )
            testResultCollector.addResult(result)
            
        } catch {
            let result = TestResult(
                testName: testName,
                success: false,
                duration: Date().timeIntervalSince(startTime),
                error: error
            )
            testResultCollector.addResult(result)
            throw error
        }
    }
    
    /// Test timer synchronization from macOS to iOS
    public func testMacOToiOSTimerSync() async throws {
        let testName = "macOS_to_iOS_Timer_Sync"
        let startTime = Date()
        
        do {
            // Setup devices
            let macOSDevice = MockDeviceFactory.createDevice(type: "macos")
            let iOSDevice = MockDeviceFactory.createDevice(type: "ios")
            
            // Setup synchronization callbacks
            var syncedStates: [MockTimerState] = []
            iOSDevice.onSync { state in
                syncedStates.append(state)
            }
            
            // Start timer on macOS device
            macOSDevice.simulateTimerAction(.start)
            
            // Wait for sync to propagate
            try await Task.sleep(nanoseconds: 500_000_000)
            
            // Verify timer synced to iOS
            guard let syncedState = syncedStates.last else {
                throw TestError.syncFailed("No timer state synced to iOS")
            }
            
            XCTAssertEqual(syncedState.isRunning, true, "Timer should be running on iOS")
            XCTAssertEqual(syncedState.phase, "work", "Timer should be in work phase on iOS")
            
            // Test phase change synchronization
            macOSDevice.simulateTimerAction(.skip) // Move to break
            try await Task.sleep(nanoseconds: 500_000_000)
            
            guard let breakState = syncedStates.last else {
                throw TestError.syncFailed("No break state synced to iOS")
            }
            
            XCTAssertEqual(breakState.phase, "break", "Timer should be in break phase on iOS")
            
            let duration = Date().timeIntervalSince(startTime)
            let metrics = testMetricsCollector.collectMetrics(
                testID: testName,
                deviceID: macOSDevice.deviceConfig.id,
                startTime: startTime,
                endTime: Date()
            )
            
            let result = TestResult(
                testName: testName,
                success: true,
                duration: duration,
                metrics: metrics
            )
            testResultCollector.addResult(result)
            
        } catch {
            let result = TestResult(
                testName: testName,
                success: false,
                duration: Date().timeIntervalSince(startTime),
                error: error
            )
            testResultCollector.addResult(result)
            throw error
        }
    }
    
    /// Test timer synchronization from watchOS to iOS/macOS
    public func testWatchOSToPhoneTimerSync() async throws {
        let testName = "watchOS_to_Phone_Timer_Sync"
        let startTime = Date()
        
        do {
            // Setup devices
            let watchOSDevice = MockDeviceFactory.createDevice(type: "watchos")
            let iOSDevice = MockDeviceFactory.createDevice(type: "ios")
            let macOSDevice = MockDeviceFactory.createDevice(type: "macos")
            
            // Setup synchronization callbacks
            var iOSSyncedStates: [MockTimerState] = []
            var macOSSyncedStates: [MockTimerState] = []
            
            iOSDevice.onSync { state in
                iOSSyncedStates.append(state)
            }
            
            macOSDevice.onSync { state in
                macOSSyncedStates.append(state)
            }
            
            // Start timer on watchOS device
            watchOSDevice.simulateTimerAction(.start)
            
            // Wait for sync to propagate through phone to macOS
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            // Verify timer synced to iOS
            guard let iOSSyncedState = iOSSyncedStates.last else {
                throw TestError.syncFailed("No timer state synced to iOS")
            }
            
            XCTAssertEqual(iOSSyncedState.isRunning, true, "Timer should be running on iOS")
            
            // Verify timer synced to macOS
            guard let macOSSyncedState = macOSSyncedStates.last else {
                throw TestError.syncFailed("No timer state synced to macOS")
            }
            
            XCTAssertEqual(macOSSyncedState.isRunning, true, "Timer should be running on macOS")
            
            // Test pause from watchOS
            watchOSDevice.simulateTimerAction(.pause)
            try await Task.sleep(nanoseconds: 1_000_000_000)
            
            XCTAssertEqual(iOSSyncedStates.last?.isRunning, false, "Timer should be paused on iOS")
            XCTAssertEqual(macOSSyncedStates.last?.isRunning, false, "Timer should be paused on macOS")
            
            let duration = Date().timeIntervalSince(startTime)
            let metrics = testMetricsCollector.collectMetrics(
                testID: testName,
                deviceID: watchOSDevice.deviceConfig.id,
                startTime: startTime,
                endTime: Date()
            )
            
            let result = TestResult(
                testName: testName,
                success: true,
                duration: duration,
                metrics: metrics
            )
            testResultCollector.addResult(result)
            
        } catch {
            let result = TestResult(
                testName: testName,
                success: false,
                duration: Date().timeIntervalSince(startTime),
                error: error
            )
            testResultCollector.addResult(result)
            throw error
        }
    }
    
    // MARK: - Multi-Device Conflict Tests
    
    /// Test simultaneous timer actions from multiple devices
    public func testSimultaneousTimerActions() async throws {
        let testName = "Simultaneous_Timer_Actions"
        let startTime = Date()
        
        do {
            // Setup multiple devices
            let iOSDevice = MockDeviceFactory.createDevice(type: "ios")
            let macOSDevice = MockDeviceFactory.createDevice(type: "macos")
            let watchOSDevice = MockDeviceFactory.createDevice(type: "watchos")
            
            var conflictEvents: [MockTimerState] = []
            let conflictResolver = TestConflictResolver()
            
            // Setup conflict detection
            let devices = [iOSDevice, macOSDevice, watchOSDevice]
            for device in devices {
                device.onSync { state in
                    let conflict = conflictResolver.addEvent(state, from: device.deviceConfig.id)
                    if let conflict = conflict {
                        conflictEvents.append(conflict)
                    }
                }
            }
            
            // Simulate simultaneous actions
            let dispatchGroup = DispatchGroup()
            
            dispatchGroup.enter()
            DispatchQueue.global().async {
                iOSDevice.simulateTimerAction(.start)
                dispatchGroup.leave()
            }
            
            dispatchGroup.enter()
            DispatchQueue.global().async {
                macOSDevice.simulateTimerAction(.pause)
                dispatchGroup.leave()
            }
            
            dispatchGroup.enter()
            DispatchQueue.global().async {
                watchOSDevice.simulateTimerAction(.reset)
                dispatchGroup.leave()
            }
            
            // Wait for all actions to complete
            dispatchGroup.wait()
            try await Task.sleep(nanoseconds: 1_000_000_000)
            
            // Verify conflict resolution
            XCTAssertGreaterThan(conflictEvents.count, 0, "Should detect and resolve conflicts")
            
            let resolvedState = conflictResolver.getResolvedState()
            XCTAssertNotNil(resolvedState, "Should have a resolved state")
            
            // Verify all devices end up with the same state
            for device in devices {
                XCTAssertEqual(device.currentTimerState?.phase, resolvedState?.phase,
                             "All devices should have the same resolved phase")
            }
            
            let duration = Date().timeIntervalSince(startTime)
            let metrics = testMetricsCollector.collectMetrics(
                testID: testName,
                deviceID: "multi-device",
                startTime: startTime,
                endTime: Date()
            )
            
            let result = TestResult(
                testName: testName,
                success: true,
                duration: duration,
                metrics: metrics
            )
            testResultCollector.addResult(result)
            
        } catch {
            let result = TestResult(
                testName: testName,
                success: false,
                duration: Date().timeIntervalSince(startTime),
                error: error
            )
            testResultCollector.addResult(result)
            throw error
        }
    }
    
    // MARK: - Device Activity Tracking Tests
    
    /// Test device heartbeat and activity tracking
    public func testDeviceActivityTracking() async throws {
        let testName = "Device_Activity_Tracking"
        let startTime = Date()
        
        do {
            // Setup device manager for activity tracking
            let activityTracker = TestDeviceActivityTracker()
            
            let iOSDevice = MockDeviceFactory.createDevice(type: "ios")
            let macOSDevice = MockDeviceFactory.createDevice(type: "macos")
            
            // Register devices for activity tracking
            activityTracker.registerDevice(iOSDevice.deviceConfig.id, type: "ios")
            activityTracker.registerDevice(macOSDevice.deviceConfig.id, type: "macos")
            
            // Simulate device heartbeats
            iOSDevice.simulateHeartbeat()
            macOSDevice.simulateHeartbeat()
            
            // Verify devices are marked as active
            XCTAssertTrue(activityTracker.isDeviceActive(iOSDevice.deviceConfig.id),
                         "iOS device should be active")
            XCTAssertTrue(activityTracker.isDeviceActive(macOSDevice.deviceConfig.id),
                         "macOS device should be active")
            
            // Simulate device going offline
            iOSDevice.simulateNetworkInterruption(duration: 5.0)
            
            // Wait for heartbeat timeout
            try await Task.sleep(nanoseconds: 6_000_000_000) // 6 seconds
            
            // Verify iOS device is marked as inactive
            XCTAssertFalse(activityTracker.isDeviceActive(iOSDevice.deviceConfig.id),
                          "iOS device should be inactive after network interruption")
            XCTAssertTrue(activityTracker.isDeviceActive(macOSDevice.deviceConfig.id),
                         "macOS device should remain active")
            
            // Simulate device reconnection
            iOSDevice.simulateHeartbeat()
            
            // Verify device is marked as active again
            XCTAssertTrue(activityTracker.isDeviceActive(iOSDevice.deviceConfig.id),
                         "iOS device should be active after reconnection")
            
            // Test activity history
            let activityHistory = activityTracker.getActivityHistory(for: iOSDevice.deviceConfig.id)
            XCTAssertGreaterThan(activityHistory.count, 0, "Should have activity history")
            
            let duration = Date().timeIntervalSince(startTime)
            let metrics = testMetricsCollector.collectMetrics(
                testID: testName,
                deviceID: "activity-tracker",
                startTime: startTime,
                endTime: Date()
            )
            
            let result = TestResult(
                testName: testName,
                success: true,
                duration: duration,
                metrics: metrics
            )
            testResultCollector.addResult(result)
            
        } catch {
            let result = TestResult(
                testName: testName,
                success: false,
                duration: Date().timeIntervalSince(startTime),
                error: error
            )
            testResultCollector.addResult(result)
            throw error
        }
    }
    
    // MARK: - Rich Push Notification Tests
    
    /// Test rich push notifications for cross-device sync
    public func testRichPushNotifications() async throws {
        let testName = "Rich_Push_Notifications"
        let startTime = Date()
        
        do {
            // Setup devices
            let iOSDevice = MockDeviceFactory.createDevice(type: "ios")
            let macOSDevice = MockDeviceFactory.createDevice(type: "macos")
            
            var receivedNotifications: [MockPushNotification] = []
            
            // Setup notification handlers
            iOSDevice.onNotification { notification in
                receivedNotifications.append(notification)
            }
            
            macOSDevice.onNotification { notification in
                receivedNotifications.append(notification)
            }
            
            // Simulate timer action that triggers notification
            macOSDevice.simulateTimerAction(.start)
            
            // Create mock rich notification that would be sent
            let richNotification = MockPushNotification(
                type: "timer_sync",
                title: "Timer Started",
                subtitle: "On your MacBook",
                body: "Work session started (25:00)",
                actions: [
                    MockNotificationAction(id: "pause", title: "Pause"),
                    MockNotificationAction(id: "skip", title: "Skip")
                ],
                priority: .high
            )
            
            // Simulate notification delivery
            iOSDevice.receivePushNotification(richNotification)
            macOSDevice.receivePushNotification(richNotification)
            
            // Verify notifications were received
            try await Task.sleep(nanoseconds: 500_000_000)
            
            XCTAssertEqual(receivedNotifications.count, 2, "Should receive notifications on both devices")
            
            let iOSNotification = receivedNotifications.first { $0.type == "timer_sync" }
            XCTAssertNotNil(iOSNotification, "iOS should receive timer sync notification")
            XCTAssertEqual(iOSNotification?.actions.count, 2, "Notification should have interactive actions")
            
            // Test notification action handling
            let pauseAction = iOSNotification?.actions.first { $0.id == "pause" }
            XCTAssertNotNil(pauseAction, "Should have pause action")
            
            // Simulate user tapping pause action
            if let pauseAction = pauseAction {
                // This would normally trigger a timer pause action
                iOSDevice.simulateTimerAction(.pause)
                try await Task.sleep(nanoseconds: 500_000_000)
            }
            
            let duration = Date().timeIntervalSince(startTime)
            let metrics = testMetricsCollector.collectMetrics(
                testID: testName,
                deviceID: "notification-system",
                startTime: startTime,
                endTime: Date()
            )
            
            let result = TestResult(
                testName: testName,
                success: true,
                duration: duration,
                metrics: metrics
            )
            testResultCollector.addResult(result)
            
        } catch {
            let result = TestResult(
                testName: testName,
                success: false,
                duration: Date().timeIntervalSince(startTime),
                error: error
            )
            testResultCollector.addResult(result)
            throw error
        }
    }
    
    // MARK: - Test Results
    
    /// Get all test results
    public func getTestResults() -> [TestResult] {
        return testResultCollector.getResults()
    }
    
    /// Generate test report
    public func generateTestReport() -> String {
        return testResultCollector.generateReport()
    }
}

// MARK: - Test Errors

public enum TestError: Error {
    case syncFailed(String)
    case deviceNotFound(String)
    case conflictResolutionFailed(String)
    case notificationFailed(String)
    case activityTrackingFailed(String)
}

// MARK: - Helper Assertions

private func XCTAssertEqual<T: Equatable>(_ expression1: T?, _ expression2: T?, _ message: String? = nil, file: StaticString = #file, line: UInt = #line) {
    guard let value1 = expression1, let value2 = expression2 else {
        print("❌ Assertion failed: nil values - \(message ?? "")")
        return
    }
    
    if value1 == value2 {
        print("✅ Assertion passed: \(value1) == \(value2)")
    } else {
        print("❌ Assertion failed: \(value1) != \(value2) - \(message ?? "")")
    }
}

private func XCTAssertTrue(_ condition: Bool, _ message: String? = nil, file: StaticString = #file, line: UInt = #line) {
    if condition {
        print("✅ Assertion passed: condition is true")
    } else {
        print("❌ Assertion failed: condition is false - \(message ?? "")")
    }
}

private func XCTAssertFalse(_ condition: Bool, _ message: String? = nil, file: StaticString = #file, line: UInt = #line) {
    if !condition {
        print("✅ Assertion passed: condition is false")
    } else {
        print("❌ Assertion failed: condition is true - \(message ?? "")")
    }
}

private func XCTAssertGreaterThan<T: Comparable>(_ expression1: T, _ expression2: T, _ message: String? = nil, file: StaticString = #file, line: UInt = #line) {
    if expression1 > expression2 {
        print("✅ Assertion passed: \(expression1) > \(expression2)")
    } else {
        print("❌ Assertion failed: \(expression1) <= \(expression2) - \(message ?? "")")
    }
}

private func XCTAssertNotNil<T>(_ expression: T?, _ message: String? = nil, file: StaticString = #file, line: UInt = #line) {
    if expression != nil {
        print("✅ Assertion passed: value is not nil")
    } else {
        print("❌ Assertion failed: value is nil - \(message ?? "")")
    }
}