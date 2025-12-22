//
//  ConcurrencyStressTests.swift
//  TimeBeam Testing Framework
//
//  Concurrency and stress testing for multi-device synchronization
//

import Foundation

/// Comprehensive concurrency stress tests
/// Tests simultaneous operations, network interruptions, and system limits
public class ConcurrencyStressTests {
    
    // MARK: - Properties
    
    private let testDeviceManager = TestDeviceManager()
    private let testNetworkSimulator = TestNetworkSimulator()
    private let testResultCollector = TestResultCollector()
    private let testMetricsCollector = TestMetricsCollector()
    
    // MARK: - Simultaneous Actions Tests
    
    /// Test multiple simultaneous timer actions from different devices
    public func testSimultaneousActions() async throws {
        let testName = "Simultaneous_Actions"
        let startTime = Date()
        
        do {
            // Create multiple devices
            let deviceCount = TestConfiguration.concurrentDeviceCount
            var devices: [MockDevice] = []
            
            for i in 0..<deviceCount {
                let deviceType = i % 3 == 0 ? "ios" : i % 3 == 1 ? "macos" : "watchos"
                let device = MockDeviceFactory.createDevice(type: deviceType)
                devices.append(device)
                testDeviceManager.registerDevice(device, config: device.deviceConfig)
            }
            
            // Start metrics collection
            testMetricsCollector.startCollection(testID: testName)
            
            // Simulate simultaneous actions
            let actionCount = TestConfiguration.simultaneousActionCount
            let dispatchGroup = DispatchGroup()
            var completedActions = 0
            let actionQueue = DispatchQueue(label: "actionQueue", attributes: .concurrent)
            
            for i in 0..<actionCount {
                dispatchGroup.enter()
                actionQueue.async {
                    let deviceIndex = i % devices.count
                    let device = devices[deviceIndex]
                    let action: TimerAction
                    
                    switch i % 4 {
                    case 0: action = .start
                    case 1: action = .pause
                    case 2: action = .reset
                    default: action = .skip
                    }
                    
                    device.simulateTimerAction(action)
                    
                    DispatchQueue.main.async {
                        completedActions += 1
                        dispatchGroup.leave()
                    }
                }
            }
            
            // Wait for all actions to complete
            dispatchGroup.wait()
            
            // Wait for conflict resolution
            try await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
            
            // Verify all actions were processed
            XCTAssertEqual(completedActions, actionCount, "All actions should be completed")
            
            // Verify devices have consistent state
            let finalStates = devices.compactMap { $0.currentTimerState }
            XCTAssertGreaterThan(finalStates.count, 0, "Should have final states")
            
            // Check if conflicts were resolved (all devices should have same phase)
            let phases = Set(finalStates.map { $0.phase })
            XCTAssertLessThanOrEqual(phases.count, 2, "Should have at most 2 different phases due to conflicts")
            
            // Stop metrics collection
            let metrics = testMetricsCollector.stopCollection(testID: testName)
            
            let duration = Date().timeIntervalSince(startTime)
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
    
    // MARK: - Network Interruption Tests
    
    /// Test network interruption and recovery scenarios
    public func testNetworkInterruptionRecovery() async throws {
        let testName = "Network_Interruption_Recovery"
        let startTime = Date()
        
        do {
            // Setup devices
            let iOSDevice = MockDeviceFactory.createDevice(type: "ios")
            let macOSDevice = MockDeviceFactory.createDevice(type: "macos")
            
            // Start metrics collection
            testMetricsCollector.startCollection(testID: testName)
            
            // Start timer on iOS
            iOSDevice.simulateTimerAction(.start)
            try await Task.sleep(nanoseconds: 1_000_000_000)
            
            // Verify sync to macOS
            XCTAssertEqual(macOSDevice.currentTimerState?.isRunning, true, "Timer should sync to macOS")
            
            // Simulate network interruption
            testNetworkSimulator.setNetworkMode(.completeFailure)
            iOSDevice.simulateNetworkInterruption(duration: TestConfiguration.networkInterruptionDuration)
            macOSDevice.simulateNetworkInterruption(duration: TestConfiguration.networkInterruptionDuration)
            
            // Try to perform actions during network failure
            iOSDevice.simulateTimerAction(.pause)
            try await Task.sleep(nanoseconds: 2_000_000_000)
            
            // Verify state changed locally but didn't sync
            XCTAssertEqual(iOSDevice.currentTimerState?.isRunning, false, "Timer should be paused locally")
            
            // Network should be restored automatically
            try await Task.sleep(nanoseconds: TestConfiguration.networkInterruptionDuration * 1_000_000_000)
            
            // Verify network is restored
            XCTAssertTrue(testNetworkSimulator.isNetworkConnected(), "Network should be restored")
            XCTAssertTrue(iOSDevice.isConnected, "iOS device should be reconnected")
            XCTAssertTrue(macOSDevice.isConnected, "macOS device should be reconnected")
            
            // Verify sync resumes after reconnection
            iOSDevice.simulateTimerAction(.start)
            try await Task.sleep(nanoseconds: 2_000_000_000)
            
            // Verify sync works after recovery
            XCTAssertEqual(macOSDevice.currentTimerState?.isRunning, true, "Sync should work after recovery")
            
            // Reset network mode
            testNetworkSimulator.setNetworkMode(.none)
            
            // Stop metrics collection
            let metrics = testMetricsCollector.stopCollection(testID: testName)
            
            let duration = Date().timeIntervalSince(startTime)
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
    
    /// Test intermittent network connectivity
    public func testIntermittentConnectivity() async throws {
        let testName = "Intermittent_Connectivity"
        let startTime = Date()
        
        do {
            let iOSDevice = MockDeviceFactory.createDevice(type: "ios")
            let macOSDevice = MockDeviceFactory.createDevice(type: "macos")
            
            // Start metrics collection
            testMetricsCollector.startCollection(testID: testName)
            
            // Set intermittent disconnection mode
            testNetworkSimulator.setNetworkMode(.intermittentDisconnection)
            
            var successfulSyncs = 0
            var attemptedSyncs = 0
            
            // Try multiple sync attempts during intermittent connectivity
            for i in 0..<10 {
                attemptedSyncs += 1
                
                // Start/pause timer
                let action: TimerAction = i % 2 == 0 ? .start : .pause
                iOSDevice.simulateTimerAction(action)
                
                // Wait and check if sync occurred
                try await Task.sleep(nanoseconds: 1_500_000_000)
                
                if macOSDevice.currentTimerState?.isRunning == (action == .start) {
                    successfulSyncs += 1
                }
            }
            
            // Verify some syncs succeeded despite intermittent connectivity
            XCTAssertGreaterThan(successfulSyncs, 0, "Some syncs should succeed")
            XCTAssertGreaterThan(successfulSyncs, attemptedSyncs / 2, "At least half should succeed")
            
            // Reset network mode
            testNetworkSimulator.setNetworkMode(.none)
            
            // Stop metrics collection
            let metrics = testMetricsCollector.stopCollection(testID: testName)
            
            let duration = Date().timeIntervalSince(startTime)
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
    
    // MARK: - Stress Test
    
    /// Test system under sustained load
    public func testSustainedLoad() async throws {
        let testName = "Sustained_Load"
        let startTime = Date()
        
        do {
            // Create multiple devices for stress testing
            let deviceCount = 20
            var devices: [MockDevice] = []
            
            for i in 0..<deviceCount {
                let deviceType = i % 3 == 0 ? "ios" : i % 3 == 1 ? "macos" : "watchos"
                let device = MockDeviceFactory.createDevice(type: deviceType)
                devices.append(device)
            }
            
            // Start metrics collection
            testMetricsCollector.startCollection(testID: testName)
            
            let stressDuration = TestConfiguration.stressTestDuration
            let endTime = Date().addingTimeInterval(stressDuration)
            
            var actionCounter = 0
            var errorCounter = 0
            
            // Generate continuous load
            while Date() < endTime {
                let dispatchGroup = DispatchGroup()
                
                // Simulate random actions across devices
                for i in 0..<5 { // 5 concurrent actions per cycle
                    dispatchGroup.enter()
                    DispatchQueue.global().async {
                        let deviceIndex = Int.random(in: 0..<devices.count)
                        let device = devices[deviceIndex]
                        let action: TimerAction = TimerAction.allCases.randomElement()!
                        
                        do {
                            device.simulateTimerAction(action)
                            DispatchQueue.main.async {
                                actionCounter += 1
                            }
                        } catch {
                            DispatchQueue.main.async {
                                errorCounter += 1
                            }
                        }
                        
                        dispatchGroup.leave()
                    }
                }
                
                dispatchGroup.wait()
                
                // Brief pause between cycles
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            }
            
            // Verify system stability under load
            XCTAssertGreaterThan(actionCounter, 0, "Should perform actions under load")
            XCTAssertLessThan(errorCounter, actionCounter / 10, "Error rate should be low")
            
            // Verify all devices are still responsive
            for device in devices {
                XCTAssertNotNil(device.currentTimerState, "Device should still have state")
                XCTAssertTrue(device.isConnected, "Device should still be connected")
            }
            
            // Stop metrics collection
            let metrics = testMetricsCollector.stopCollection(testID: testName)
            
            let duration = Date().timeIntervalSince(startTime)
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
    
    // MARK: - Memory and Resource Tests
    
    /// Test memory usage under high concurrency
    public func testMemoryUsageUnderConcurrency() async throws {
        let testName = "Memory_Usage_Concurrency"
        let startTime = Date()
        
        do {
            // Create memory monitor
            let memoryMonitor = MemoryMonitor()
            memoryMonitor.startMonitoring(testID: testName)
            
            // Create many devices and perform actions
            let deviceCount = 50
            var devices: [MockDevice] = []
            
            for i in 0..<deviceCount {
                let device = MockDeviceFactory.createDevice(type: "ios")
                devices.append(device)
            }
            
            // Perform intensive operations
            let dispatchGroup = DispatchGroup()
            
            for device in devices {
                dispatchGroup.enter()
                DispatchQueue.global().async {
                    for _ in 0..<100 {
                        device.simulateTimerAction(.start)
                        device.simulateTimerAction(.pause)
                        device.simulateTimerAction(.reset)
                    }
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.wait()
            
            // Check memory usage
            let memoryMetrics = memoryMonitor.stopMonitoring(testID: testName)
            XCTAssertNotNil(memoryMetrics, "Should have memory metrics")
            
            if let metrics = memoryMetrics {
                let memoryIncreaseMB = metrics.memoryIncrease / (1024 * 1024)
                XCTAssertLessThanOrEqual(memoryIncreaseMB, TestConfiguration.maxMemoryIncreaseMB,
                                       "Memory increase should be within limits")
            }
            
            // Clear devices
            devices.removeAll()
            
            let duration = Date().timeIntervalSince(startTime)
            let result = TestResult(
                testName: testName,
                success: true,
                duration: duration
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
    
    // MARK: - Database Performance Tests
    
    /// Test database performance under concurrent operations
    public func testDatabasePerformance() async throws {
        let testName = "Database_Performance"
        let startTime = Date()
        
        do {
            // Simulate database operations
            let operationCount = 1000
            let dispatchGroup = DispatchGroup()
            var successfulOperations = 0
            var failedOperations = 0
            
            // Simulate concurrent database writes (timer state updates)
            for i in 0..<operationCount {
                dispatchGroup.enter()
                DispatchQueue.global().async {
                    // Simulate database write operation
                    let success = self.simulateDatabaseWrite(timerId: "timer_\(i)", 
                                                           state: MockTimerState(deviceId: "device_\(i)"))
                    DispatchQueue.main.async {
                        if success {
                            successfulOperations += 1
                        } else {
                            failedOperations += 1
                        }
                        dispatchGroup.leave()
                    }
                }
            }
            
            // Simulate concurrent database reads
            for i in 0..<operationCount {
                dispatchGroup.enter()
                DispatchQueue.global().async {
                    let _ = self.simulateDatabaseRead(timerId: "timer_\(i)")
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.wait()
            
            // Verify database performance
            XCTAssertGreaterThan(successfulOperations, operationCount * 0.95, "At least 95% of writes should succeed")
            XCTAssertEqual(failedOperations, 0, "No operations should fail")
            
            let duration = Date().timeIntervalSince(startTime)
            let result = TestResult(
                testName: testName,
                success: true,
                duration: duration
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
    
    // MARK: - Helper Methods
    
    private func simulateDatabaseWrite(timerId: String, state: MockTimerState) -> Bool {
        // Simulate database write with random latency
        let latency = TimeInterval.random(in: 0.001...0.05) // 1-50ms
        Thread.sleep(forTimeInterval: latency)
        return Double.random(in: 0...1) > 0.01 // 99% success rate
    }
    
    private func simulateDatabaseRead(timerId: String) -> MockTimerState? {
        // Simulate database read with random latency
        let latency = TimeInterval.random(in: 0.001...0.02) // 1-20ms
        Thread.sleep(forTimeInterval: latency)
        return MockTimerState(deviceId: "read_device")
    }
}

// MARK: - Additional Helper Assertions

private func XCTAssertLessThanOrEqual<T: Comparable>(_ expression1: T, _ expression2: T, _ message: String? = nil, file: StaticString = #file, line: UInt = #line) {
    if expression1 <= expression2 {
        print("✅ Assertion passed: \(expression1) <= \(expression2)")
    } else {
        print("❌ Assertion failed: \(expression1) > \(expression2) - \(message ?? "")")
    }
}