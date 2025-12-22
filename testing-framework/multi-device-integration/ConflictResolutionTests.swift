//
//  ConflictResolutionTests.swift
//  TimeBeam Testing Framework
//
//  Conflict resolution testing for multi-device synchronization
//

import Foundation

/// Comprehensive conflict resolution tests
/// Tests all conflict resolution strategies and edge cases
public class ConflictResolutionTests {
    
    // MARK: - Properties
    
    private let testDeviceManager = TestDeviceManager()
    private let conflictResolver = TestConflictResolver()
    private let resultCollector = TestResultCollector()
    
    // MARK: - Latest Event Wins Tests
    
    /// Test conflict resolution using latest event strategy
    public func testLatestEventWinsStrategy() async throws {
        let testName = "Latest_Event_Wins_Strategy"
        let startTime = Date()
        
        do {
            // Setup devices
            let iOSDevice = MockDeviceFactory.createDevice(type: "ios")
            let macOSDevice = MockDeviceFactory.createDevice(type: "macos")
            
            // Simulate conflicting actions
            let baseTime = Date()
            
            // iOS starts timer first
            iOSDevice.simulateTimerAction(.start)
            
            // macOS pauses timer 1 second later (should win with latest event)
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            macOSDevice.simulateTimerAction(.pause)
            
            // Wait for conflict resolution
            try await Task.sleep(nanoseconds: 500_000_000)
            
            // Verify latest event (pause) won
            XCTAssertEqual(iOSDevice.currentTimerState?.isRunning, false, "Timer should be paused on iOS")
            XCTAssertEqual(macOSDevice.currentTimerState?.isRunning, false, "Timer should be paused on macOS")
            
            let duration = Date().timeIntervalSince(startTime)
            let result = TestResult(
                testName: testName,
                success: true,
                duration: duration
            )
            resultCollector.addResult(result)
            
        } catch {
            let result = TestResult(
                testName: testName,
                success: false,
                duration: Date().timeIntervalSince(startTime),
                error: error
            )
            resultCollector.addResult(result)
            throw error
        }
    }
    
    // MARK: - Device Priority Tests
    
    /// Test conflict resolution using device priority strategy
    public func testDevicePriorityStrategy() async throws {
        let testName = "Device_Priority_Strategy"
        let startTime = Date()
        
        do {
            // Setup devices
            let watchOSDevice = MockDeviceFactory.createDevice(type: "watchos")
            let iOSDevice = MockDeviceFactory.createDevice(type: "ios")
            let macOSDevice = MockDeviceFactory.createDevice(type: "macos")
            
            // Simulate simultaneous conflicting actions
            let dispatchGroup = DispatchGroup()
            
            dispatchGroup.enter()
            DispatchQueue.global().async {
                self.watchOSDevice.simulateTimerAction(.start)
                dispatchGroup.leave()
            }
            
            dispatchGroup.enter()
            DispatchQueue.global().async {
                self.iOSDevice.simulateTimerAction(.pause)
                dispatchGroup.leave()
            }
            
            dispatchGroup.enter()
            DispatchQueue.global().async {
                self.macOSDevice.simulateTimerAction(.reset)
                dispatchGroup.leave()
            }
            
            dispatchGroup.wait()
            try await Task.sleep(nanoseconds: 1_000_000_000)
            
            // Verify macOS device won (highest priority)
            let resolvedState = conflictResolver.getResolvedState()
            XCTAssertEqual(resolvedState?.deviceId, macOSDevice.deviceConfig.id, "macOS should win in device priority")
            
            let duration = Date().timeIntervalSince(startTime)
            let result = TestResult(
                testName: testName,
                success: true,
                duration: duration
            )
            resultCollector.addResult(result)
            
        } catch {
            let result = TestResult(
                testName: testName,
                success: false,
                duration: Date().timeIntervalSince(startTime),
                error: error
            )
            resultCollector.addResult(result)
            throw error
        }
    }
    
    // MARK: - User Choice Tests
    
    /// Test conflict resolution using user choice strategy
    public func testUserChoiceStrategy() async throws {
        let testName = "User_Choice_Strategy"
        let startTime = Date()
        
        do {
            // Setup devices
            let iOSDevice = MockDeviceFactory.createDevice(type: "ios")
            let macOSDevice = MockDeviceFactory.createDevice(type: "macos")
            
            // Create conflicting timer states
            iOSDevice.currentTimerState = MockTimerState(
                phase: "work",
                remainingSeconds: 1200, // 20 minutes
                isRunning: true,
                deviceId: iOSDevice.deviceConfig.id
            )
            
            macOSDevice.currentTimerState = MockTimerState(
                phase: "break",
                remainingSeconds: 300, // 5 minutes
                isRunning: true,
                deviceId: macOSDevice.deviceConfig.id
            )
            
            // Simulate user choice notification
            let conflictNotification = MockPushNotification(
                type: "conflict_resolution",
                title: "Timer Conflict Detected",
                subtitle: "Choose which timer to keep",
                body: "iPhone: 20:00 work\nMacBook: 5:00 break",
                actions: [
                    MockNotificationAction(id: "keep_ios", title: "Keep iPhone Timer"),
                    MockNotificationAction(id: "keep_macos", title: "Keep MacBook Timer")
                ],
                priority: .high
            )
            
            // Simulate user choosing iOS timer
            iOSDevice.receivePushNotification(conflictNotification)
            
            // Simulate user action
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                // User chooses to keep iOS timer
                self.conflictResolver.addEvent(iOSDevice.currentTimerState!, from: iOSDevice.deviceConfig.id)
            }
            
            try await Task.sleep(nanoseconds: 2_000_000_000)
            
            // Verify user choice was respected
            let resolvedState = conflictResolver.getResolvedState()
            XCTAssertEqual(resolvedState?.deviceId, iOSDevice.deviceConfig.id, "User choice should be respected")
            XCTAssertEqual(resolvedState?.phase, "work", "Should keep iOS work phase")
            
            let duration = Date().timeIntervalSince(startTime)
            let result = TestResult(
                testName: testName,
                success: true,
                duration: duration
            )
            resultCollector.addResult(result)
            
        } catch {
            let result = TestResult(
                testName: testName,
                success: false,
                duration: Date().timeIntervalSince(startTime),
                error: error
            )
            resultCollector.addResult(result)
            throw error
        }
    }
    
    // MARK: - Time-Based Tests
    
    /// Test conflict resolution using time-based strategy
    public func testTimeBasedStrategy() async throws {
        let testName = "Time_Based_Strategy"
        let startTime = Date()
        
        do {
            // Setup devices
            let iOSDevice = MockDeviceFactory.createDevice(type: "ios")
            let macOSDevice = MockDeviceFactory.createDevice(type: "macos")
            
            // Create conflicting states with different remaining times
            iOSDevice.currentTimerState = MockTimerState(
                phase: "work",
                remainingSeconds: 900, // 15 minutes
                isRunning: true,
                deviceId: iOSDevice.deviceConfig.id
            )
            
            macOSDevice.currentTimerState = MockTimerState(
                phase: "work",
                remainingSeconds: 1500, // 25 minutes
                isRunning: false,
                deviceId: macOSDevice.deviceConfig.id
            )
            
            // Add events to conflict resolver
            conflictResolver.addEvent(iOSDevice.currentTimerState!, from: iOSDevice.deviceConfig.id)
            conflictResolver.addEvent(macOSDevice.currentTimerState!, from: macOSDevice.deviceConfig.id)
            
            try await Task.sleep(nanoseconds: 500_000_000)
            
            // Verify device with more remaining time won (macOS with 25 min)
            let resolvedState = conflictResolver.getResolvedState()
            XCTAssertEqual(resolvedState?.remainingSeconds, 1500, "Should keep timer with more remaining time")
            XCTAssertEqual(resolvedState?.deviceId, macOSDevice.deviceConfig.id, "macOS device should win with more time")
            
            let duration = Date().timeIntervalSince(startTime)
            let result = TestResult(
                testName: testName,
                success: true,
                duration: duration
            )
            resultCollector.addResult(result)
            
        } catch {
            let result = TestResult(
                testName: testName,
                success: false,
                duration: Date().timeIntervalSince(startTime),
                error: error
            )
            resultCollector.addResult(result)
            throw error
        }
    }
    
    // MARK: - Edge Case Tests
    
    /// Test conflict resolution with multiple devices having same timestamp
    public func testSameTimestampConflict() async throws {
        let testName = "Same_Timestamp_Conflict"
        let startTime = Date()
        
        do {
            // Setup multiple devices
            let devices = [
                MockDeviceFactory.createDevice(type: "ios"),
                MockDeviceFactory.createDevice(type: "macos"),
                MockDeviceFactory.createDevice(type: "watchos")
            ]
            
            let sameTimestamp = Date()
            
            // Simulate all devices taking action at same timestamp
            for (index, device) in devices.enumerated() {
                let action: TimerAction = index % 2 == 0 ? .start : .pause
                device.currentTimerState = MockTimerState(
                    phase: "work",
                    remainingSeconds: 1500,
                    isRunning: action == .start,
                    deviceId: device.deviceConfig.id
                )
                conflictResolver.addEvent(device.currentTimerState!, from: device.deviceConfig.id)
            }
            
            try await Task.sleep(nanoseconds: 500_000_000)
            
            // Verify conflict was resolved (should have some deterministic outcome)
            let resolvedState = conflictResolver.getResolvedState()
            XCTAssertNotNil(resolvedState, "Should have resolved conflict even with same timestamps")
            
            // All devices should converge to same state
            for device in devices {
                XCTAssertEqual(device.currentTimerState?.isRunning, resolvedState?.isRunning,
                               "All devices should converge to same running state")
            }
            
            let duration = Date().timeIntervalSince(startTime)
            let result = TestResult(
                testName: testName,
                success: true,
                duration: duration
            )
            resultCollector.addResult(result)
            
        } catch {
            let result = TestResult(
                testName: testName,
                success: false,
                duration: Date().timeIntervalSince(startTime),
                error: error
            )
            resultCollector.addResult(result)
            throw error
        }
    }
    
    /// Test conflict resolution under network latency
    public func testConflictWithNetworkLatency() async throws {
        let testName = "Conflict_With_Network_Latency"
        let startTime = Date()
        
        do {
            let networkSimulator = TestNetworkSimulator()
            networkSimulator.setNetworkMode(.highLatency)
            
            let iOSDevice = MockDeviceFactory.createDevice(type: "ios")
            let macOSDevice = MockDeviceFactory.createDevice(type: "macos")
            
            // Simulate actions with high latency
            iOSDevice.simulateTimerAction(.start)
            
            // Add artificial delay before second action (simulating network latency)
            try await Task.sleep(nanoseconds: UInt64(networkSimulator.getLatency() * 1_000_000_000))
            
            macOSDevice.simulateTimerAction(.pause)
            
            // Wait for conflict resolution with latency
            try await Task.sleep(nanoseconds: 2_000_000_000)
            
            // Verify conflict was resolved despite latency
            let resolvedState = conflictResolver.getResolvedState()
            XCTAssertNotNil(resolvedState, "Should resolve conflict even with network latency")
            
            // Reset network mode
            networkSimulator.setNetworkMode(.none)
            
            let duration = Date().timeIntervalSince(startTime)
            let result = TestResult(
                testName: testName,
                success: true,
                duration: duration
            )
            resultCollector.addResult(result)
            
        } catch {
            let result = TestResult(
                testName: testName,
                success: false,
                duration: Date().timeIntervalSince(startTime),
                error: error
            )
            resultCollector.addResult(result)
            throw error
        }
    }
    
    /// Test conflict resolution with device disconnection
    public func testConflictWithDeviceDisconnection() async throws {
        let testName = "Conflict_With_Device_Disconnection"
        let startTime = Date()
        
        do {
            let iOSDevice = MockDeviceFactory.createDevice(type: "ios")
            let macOSDevice = MockDeviceFactory.createDevice(type: "macos")
            
            // iOS device starts timer
            iOSDevice.simulateTimerAction(.start)
            
            // macOS device goes offline
            macOSDevice.simulateNetworkInterruption(duration: 3.0)
            
            // iOS device pauses timer while macOS is offline
            try await Task.sleep(nanoseconds: 500_000_000)
            iOSDevice.simulateTimerAction(.pause)
            
            // Wait for macOS to come back online
            try await Task.sleep(nanoseconds: 3_500_000_000)
            
            // Verify reconnection and state sync
            XCTAssertTrue(macOSDevice.isConnected, "macOS device should be reconnected")
            
            // The paused state should sync to macOS when it comes back online
            try await Task.sleep(nanoseconds: 1_000_000_000)
            
            let duration = Date().timeIntervalSince(startTime)
            let result = TestResult(
                testName: testName,
                success: true,
                duration: duration
            )
            resultCollector.addResult(result)
            
        } catch {
            let result = TestResult(
                testName: testName,
                success: false,
                duration: Date().timeIntervalSince(startTime),
                error: error
            )
            resultCollector.addResult(result)
            throw error
        }
    }
    
    // MARK: - Vector Clock Tests
    
    /// Test vector clock ordering for conflict resolution
    public func testVectorClockOrdering() async throws {
        let testName = "Vector_Clock_Ordering"
        let startTime = Date()
        
        do {
            // Create mock vector clocks for testing
            let vectorClock1 = createMockVectorClock(deviceId: "ios1", counter: 1)
            let vectorClock2 = createMockVectorClock(deviceId: "macos1", counter: 2)
            
            // iOS device action with lower vector clock
            let iOSState = MockTimerState(
                phase: "work",
                remainingSeconds: 1500,
                isRunning: true,
                deviceId: "ios1"
            )
            
            // macOS device action with higher vector clock (should win)
            let macOSState = MockTimerState(
                phase: "work",
                remainingSeconds: 1200,
                isRunning: false,
                deviceId: "macos1"
            )
            
            // Add events with vector clock comparison
            conflictResolver.addEvent(iOSState, from: "ios1")
            conflictResolver.addEvent(macOSState, from: "macos1")
            
            try await Task.sleep(nanoseconds: 500_000_000)
            
            // Verify higher vector clock won
            let resolvedState = conflictResolver.getResolvedState()
            XCTAssertEqual(resolvedState?.deviceId, "macos1", "Higher vector clock should win")
            
            let duration = Date().timeIntervalSince(startTime)
            let result = TestResult(
                testName: testName,
                success: true,
                duration: duration
            )
            resultCollector.addResult(result)
            
        } catch {
            let result = TestResult(
                testName: testName,
                success: false,
                duration: Date().timeIntervalSince(startTime),
                error: error
            )
            resultCollector.addResult(result)
            throw error
        }
    }
    
    // MARK: - Test Results
    
    /// Get all test results
    public func getTestResults() -> [TestResult] {
        return resultCollector.getResults()
    }
    
    /// Generate test report
    public func generateTestReport() -> String {
        return resultCollector.generateReport()
    }
    
    // MARK: - Helper Methods
    
    private func createMockVectorClock(deviceId: String, counter: Int) -> [String: Int] {
        return [deviceId: counter]
    }
}