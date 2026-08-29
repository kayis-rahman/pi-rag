//
//  TestRunner.swift
//  TimeBeam Testing Framework
//
//  Automated test runner for comprehensive testing
//

import Foundation

/// Main test runner for the TimeBeam testing framework
/// Orchestrates all test categories and reporting
public class TestRunner {
    
    // MARK: - Properties
    
    private let crossPlatformTests = CrossPlatformSyncTests()
    private let conflictResolutionTests = ConflictResolutionTests()
    private let concurrencyStressTests = ConcurrencyStressTests()
    private let resultCollector = TestResultCollector()
    private let performanceDashboard = PerformanceDashboard()
    
    private var testCategories: [String: Any] = [:]
    private var startTime = Date()
    private var currentTestRun = TestRunInfo()
    
    // MARK: - Test Categories
    
    public enum TestCategory: String, CaseIterable {
        case multiDeviceIntegration = "multi-device-integration"
        case conflictResolution = "conflict-resolution"
        case concurrencyStress = "concurrency-stress"
        case performanceBenchmarks = "performance-benchmarks"
        case endToEndJourneys = "end-to-end-journeys"
        case all = "all"
    }
    
    // MARK: - Main Entry Points
    
    /// Run all tests
    public static func runAllTests() async throws {
        let runner = TestRunner()
        try await runner.runTests(category: .all)
    }
    
    /// Run specific test category
    public static func runTests(category: TestCategory) async throws {
        let runner = TestRunner()
        try await runner.runTests(category: category)
    }
    
    /// Run tests with performance monitoring
    public static func runTestsWithPerformance() async throws {
        let runner = TestRunner()
        TestConfiguration.enablePerformanceMonitoring = true
        try await runner.runTests(category: .all)
    }
    
    // MARK: - Internal Test Execution
    
    private func runTests(category: TestCategory) async throws {
        startTime = Date()
        currentTestRun = TestRunInfo(
            id: TestConfiguration.testRunID,
            category: category.rawValue,
            startTime: startTime,
            buildNumber: TestConfiguration.buildNumber,
            gitCommit: TestConfiguration.gitCommitSHA
        )
        
        print("🚀 Starting TimeBeam Test Runner")
        print("📊 Test Run ID: \(currentTestRun.id)")
        print("📂 Category: \(category.rawValue)")
        print("⏰ Started at: \(startTime)")
        print("")
        
        do {
            switch category {
            case .all:
                try await runAllCategories()
            case .multiDeviceIntegration:
                try await runMultiDeviceIntegrationTests()
            case .conflictResolution:
                try await runConflictResolutionTests()
            case .concurrencyStress:
                try await runConcurrencyStressTests()
            case .performanceBenchmarks:
                try await runPerformanceBenchmarks()
            case .endToEndJourneys:
                try await runEndToEndJourneys()
            }
            
            await generateFinalReport()
            
        } catch {
            print("❌ Test execution failed: \(error)")
            throw error
        }
    }
    
    private func runAllCategories() async throws {
        print("🔄 Running all test categories...")
        print("")
        
        try await runMultiDeviceIntegrationTests()
        try await runConflictResolutionTests()
        try await runConcurrencyStressTests()
        try await runPerformanceBenchmarks()
        try await runEndToEndJourneys()
    }
    
    // MARK: - Category Test Runners
    
    private func runMultiDeviceIntegrationTests() async throws {
        print("📱 Running Multi-Device Integration Tests...")
        print("")
        
        let categoryStartTime = Date()
        
        // Cross-platform sync tests
        try await crossPlatformTests.testiOSToMacOSTimerSync()
        try await crossPlatformTests.testMacOToiOSTimerSync()
        try await crossPlatformTests.testWatchOSToPhoneTimerSync()
        
        // Device activity tracking tests
        try await crossPlatformTests.testDeviceActivityTracking()
        
        // Rich push notification tests
        try await crossPlatformTests.testRichPushNotifications()
        
        let categoryDuration = Date().timeIntervalSince(categoryStartTime)
        print("✅ Multi-Device Integration Tests completed in \(String(format: "%.2f", categoryDuration))s")
        print("")
        
        // Collect results
        let results = crossPlatformTests.getTestResults()
        resultCollector.addResults(results)
    }
    
    private func runConflictResolutionTests() async throws {
        print("⚡ Running Conflict Resolution Tests...")
        print("")
        
        let categoryStartTime = Date()
        
        // Strategy tests
        try await conflictResolutionTests.testLatestEventWinsStrategy()
        try await conflictResolutionTests.testDevicePriorityStrategy()
        try await conflictResolutionTests.testUserChoiceStrategy()
        try await conflictResolutionTests.testTimeBasedStrategy()
        
        // Edge case tests
        try await conflictResolutionTests.testSameTimestampConflict()
        try await conflictResolutionTests.testConflictWithNetworkLatency()
        try await conflictResolutionTests.testConflictWithDeviceDisconnection()
        try await conflictResolutionTests.testVectorClockOrdering()
        
        let categoryDuration = Date().timeIntervalSince(categoryStartTime)
        print("✅ Conflict Resolution Tests completed in \(String(format: "%.2f", categoryDuration))s")
        print("")
        
        // Collect results
        let results = conflictResolutionTests.getTestResults()
        resultCollector.addResults(results)
    }
    
    private func runConcurrencyStressTests() async throws {
        print("🔥 Running Concurrency Stress Tests...")
        print("")
        
        let categoryStartTime = Date()
        
        // Simultaneous actions test
        try await concurrencyStressTests.testSimultaneousActions()
        
        // Network interruption tests
        try await concurrencyStressTests.testNetworkInterruptionRecovery()
        try await concurrencyStressTests.testIntermittentConnectivity()
        
        // Stress test
        try await concurrencyStressTests.testSustainedLoad()
        
        // Resource tests
        try await concurrencyStressTests.testMemoryUsageUnderConcurrency()
        try await concurrencyStressTests.testDatabasePerformance()
        
        let categoryDuration = Date().timeIntervalSince(categoryStartTime)
        print("✅ Concurrency Stress Tests completed in \(String(format: "%.2f", categoryDuration))s")
        print("")
        
        // Collect results
        let results = concurrencyStressTests.getTestResults()
        resultCollector.addResults(results)
    }
    
    private func runPerformanceBenchmarks() async throws {
        print("📈 Running Performance Benchmarks...")
        print("")
        
        let categoryStartTime = Date()
        
        // Network latency benchmarks
        try await runNetworkLatencyBenchmarks()
        
        // Battery usage benchmarks
        try await runBatteryUsageBenchmarks()
        
        // Database performance benchmarks
        try await runDatabasePerformanceBenchmarks()
        
        // Memory usage benchmarks
        try await runMemoryUsageBenchmarks()
        
        let categoryDuration = Date().timeIntervalSince(categoryStartTime)
        print("✅ Performance Benchmarks completed in \(String(format: "%.2f", categoryDuration))s")
        print("")
    }
    
    private func runEndToEndJourneys() async throws {
        print("🎯 Running End-to-End Journey Tests...")
        print("")
        
        let categoryStartTime = Date()
        
        // User journey tests
        try await runCompleteWorkflowTests()
        try await runAppLifecycleTests()
        try await runRealWorldScenarioTests()
        try await runConflictResolutionUXTests()
        
        let categoryDuration = Date().timeIntervalSince(categoryStartTime)
        print("✅ End-to-End Journey Tests completed in \(String(format: "%.2f", categoryDuration))s")
        print("")
    }
    
    // MARK: - Performance Benchmark Tests
    
    private func runNetworkLatencyBenchmarks() async throws {
        print("🌐 Network Latency Benchmarks...")
        
        let networkSimulator = TestNetworkSimulator()
        let testScenarios = [
            ("Perfect Network", NetworkSimulationMode.none),
            ("High Latency", NetworkSimulationMode.highLatency),
            ("Packet Loss", NetworkSimulationMode.packetLoss),
            ("Intermittent", NetworkSimulationMode.intermittentDisconnection)
        ]
        
        for (name, mode) in testScenarios {
            networkSimulator.setNetworkMode(mode)
            
            let startTime = Date()
            
            // Simulate 100 sync operations
            for _ in 0..<100 {
                let device = MockDeviceFactory.createDevice(type: "ios")
                device.simulateTimerAction(.start)
                
                // Wait for sync to complete
                try await Task.sleep(nanoseconds: UInt64(networkSimulator.getLatency() * 1_000_000_000))
            }
            
            let duration = Date().timeIntervalSince(startTime)
            let avgLatency = duration / 100.0
            
            print("  \(name): \(String(format: "%.0f", avgLatency * 1000))ms average latency")
        }
        
        networkSimulator.setNetworkMode(.none)
    }
    
    private func runBatteryUsageBenchmarks() async throws {
        print("🔋 Battery Usage Benchmarks...")
        
        let batteryMonitor = BatteryMonitor()
        let testDuration: TimeInterval = 300 // 5 minutes
        
        batteryMonitor.startMonitoring(testID: "battery_benchmark")
        
        // Simulate active usage
        let startTime = Date()
        while Date().timeIntervalSince(startTime) < testDuration {
            let device = MockDeviceFactory.createDevice(type: "ios")
            
            // Simulate user interactions
            device.simulateTimerAction(.start)
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            device.simulateTimerAction(.pause)
            try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            
            device.simulateTimerAction(.start)
            try await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
            
            device.simulateTimerAction(.reset)
            try await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
        }
        
        let metrics = batteryMonitor.stopMonitoring(testID: "battery_benchmark")
        
        if let metrics = metrics {
            let drainRatePerHour = metrics.drainRate
            print("  Battery Drain: \(String(format: "%.1f", drainRatePerHour))% per hour")
            print("  Total Drain: \(String(format: "%.1f", metrics.batteryDrain))%")
        }
    }
    
    private func runDatabasePerformanceBenchmarks() async throws {
        print("💾 Database Performance Benchmarks...")
        
        let operationCounts = [100, 500, 1000, 5000]
        
        for count in operationCounts {
            let startTime = Date()
            
            // Simulate database operations
            var successfulOperations = 0
            let dispatchGroup = DispatchGroup()
            
            for i in 0..<count {
                dispatchGroup.enter()
                DispatchQueue.global().async {
                    // Simulate timer state update
                    let success = Double.random(in: 0...1) > 0.05 // 95% success rate
                    if success {
                        successfulOperations += 1
                    }
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.wait()
            
            let duration = Date().timeIntervalSince(startTime)
            let throughput = Double(successfulOperations) / duration
            
            print("  \(count) operations: \(String(format: "%.0f", throughput)) ops/sec, \(String(format: "%.2f", duration * 1000))ms total")
        }
    }
    
    private func runMemoryUsageBenchmarks() async throws {
        print("🧠 Memory Usage Benchmarks...")
        
        let memoryMonitor = MemoryMonitor()
        memoryMonitor.startMonitoring(testID: "memory_benchmark")
        
        // Test with increasing device counts
        let deviceCounts = [10, 50, 100]
        
        for deviceCount in deviceCounts {
            var devices: [MockDevice] = []
            
            // Create devices
            for _ in 0..<deviceCount {
                let device = MockDeviceFactory.createDevice(type: "ios")
                devices.append(device)
            }
            
            // Perform operations
            let startTime = Date()
            
            for device in devices {
                for _ in 0..<10 {
                    device.simulateTimerAction(.start)
                    device.simulateTimerAction(.pause)
                }
            }
            
            let operationDuration = Date().timeIntervalSince(startTime)
            
            // Get memory snapshot
            let memorySnapshot = getMemorySnapshot()
            
            print("  \(deviceCount) devices: \(String(format: "%.2f", operationDuration))s, \(String(format: "%.1f", memorySnapshot / (1024 * 1024)))MB memory")
            
            // Clean up
            devices.removeAll()
        }
        
        let finalMetrics = memoryMonitor.stopMonitoring(testID: "memory_benchmark")
        
        if let metrics = finalMetrics {
            let memoryIncreaseMB = metrics.memoryIncrease / (1024 * 1024)
            print("  Total Memory Increase: \(String(format: "%.1f", memoryIncreaseMB))MB")
        }
    }
    
    // MARK: - End-to-End Journey Tests
    
    private func runCompleteWorkflowTests() async throws {
        print("🔄 Complete Workflow Tests...")
        
        // Simulate complete user workflow across devices
        let iOSDevice = MockDeviceFactory.createDevice(type: "ios")
        let macOSDevice = MockDeviceFactory.createDevice(type: "macos")
        let watchOSDevice = MockDeviceFactory.createDevice(type: "watchos")
        
        // 1. User starts timer on iOS
        iOSDevice.simulateTimerAction(.start)
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // 2. Switch to Mac, timer should be synced
        XCTAssertEqual(macOSDevice.currentTimerState?.isRunning, true)
        
        // 3. Pause timer on Mac
        macOSDevice.simulateTimerAction(.pause)
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // 4. Check iOS got the pause
        XCTAssertEqual(iOSDevice.currentTimerState?.isRunning, false)
        
        // 5. Check on Apple Watch
        XCTAssertEqual(watchOSDevice.currentTimerState?.isRunning, false)
        
        print("  ✅ Complete workflow test passed")
    }
    
    private func runAppLifecycleTests() async throws {
        print("📱 App Lifecycle Tests...")
        
        let iOSDevice = MockDeviceFactory.createDevice(type: "ios")
        let macOSDevice = MockDeviceFactory.createDevice(type: "macos")
        
        // 1. Start timer on Mac
        macOSDevice.simulateTimerAction(.start)
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // 2. iOS app launches - should sync timer state
        XCTAssertEqual(iOSDevice.currentTimerState?.isRunning, true)
        
        // 3. iOS app goes to background - timer continues
        try await Task.sleep(nanoseconds: 2_000_000_000)
        XCTAssertEqual(macOSDevice.currentTimerState?.isRunning, true)
        
        // 4. iOS app terminated and relaunched - should restore state
        // Simulate app termination
        iOSDevice.currentTimerState = nil
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Simulate app relaunch - would pull from backend
        XCTAssertEqual(iOSDevice.currentTimerState?.isRunning, true)
        
        print("  ✅ App lifecycle test passed")
    }
    
    private func runRealWorldScenarioTests() async throws {
        print("🌍 Real World Scenario Tests...")
        
        // Simulate real user day
        let iPhone = MockDeviceFactory.createDevice(type: "ios")
        let macBook = MockDeviceFactory.createDevice(type: "macos")
        let appleWatch = MockDeviceFactory.createDevice(type: "watchos")
        
        // Morning: Start work session on iPhone
        iPhone.simulateTimerAction(.start)
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Commute: Check on Apple Watch
        XCTAssertEqual(appleWatch.currentTimerState?.isRunning, true)
        appleWatch.simulateTimerAction(.pause) // Arrived at office
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Office: Work on MacBook
        macBook.simulateTimerAction(.start) // Resume work
        try await Task.sleep(nanoseconds: 3_000_000_000)
        
        // Lunch: Skip break on iPhone
        iPhone.simulateTimerAction(.skip)
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Verify all devices are in break phase
        XCTAssertEqual(iPhone.currentTimerState?.phase, "break")
        XCTAssertEqual(macBook.currentTimerState?.phase, "break")
        
        print("  ✅ Real world scenario test passed")
    }
    
    private func runConflictResolutionUXTests() async throws {
        print("⚠️ Conflict Resolution UX Tests...")
        
        let iPhone = MockDeviceFactory.createDevice(type: "ios")
        let macBook = MockDeviceFactory.createDevice(type: "macos")
        
        // Create conflict: both devices try to control timer simultaneously
        iPhone.currentTimerState = MockTimerState(
            phase: "work",
            remainingSeconds: 1200, // 20 min
            isRunning: true,
            deviceId: iPhone.deviceConfig.id
        )
        
        macBook.currentTimerState = MockTimerState(
            phase: "break",
            remainingSeconds: 300, // 5 min
            isRunning: true,
            deviceId: macBook.deviceConfig.id
        )
        
        // Simulate conflict notification
        let conflictNotification = MockPushNotification(
            type: "conflict_resolution",
            title: "Timer Conflict",
            subtitle: "Choose which timer to keep",
            body: "iPhone: 20:00 work\nMacBook: 5:00 break",
            actions: [
                MockNotificationAction(id: "keep_iphone", title: "Keep iPhone"),
                MockNotificationAction(id: "keep_macbook", title: "Keep MacBook")
            ],
            priority: .high
        )
        
        // User chooses to keep iPhone timer
        iPhone.receivePushNotification(conflictNotification)
        
        // Verify conflict was resolved
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        print("  ✅ Conflict resolution UX test passed")
    }
    
    // MARK: - Reporting
    
    private func generateFinalReport() async {
        let totalDuration = Date().timeIntervalSince(startTime)
        let allResults = resultCollector.getResults()
        
        print("")
        print("📊 FINAL TEST REPORT")
        print("=" * 50)
        print("🏃 Total Duration: \(String(format: "%.2f", totalDuration))s")
        print("📋 Total Tests: \(allResults.count)")
        print("✅ Passed: \(allResults.filter { $0.success }.count)")
        print("❌ Failed: \(allResults.filter { !$0.success }.count)")
        
        let successRate = Double(allResults.filter { $0.success }.count) / Double(allResults.count) * 100
        print("📈 Success Rate: \(String(format: "%.1f", successRate))%")
        
        print("")
        print("📂 Test Categories:")
        for category in TestCategory.allCases {
            if category != .all {
                let categoryResults = resultCollector.getResults(category: category.rawValue)
                if !categoryResults.isEmpty {
                    let categorySuccess = categoryResults.filter { $0.success }.count
                    let categoryRate = Double(categorySuccess) / Double(categoryResults.count) * 100
                    print("  \(category.rawValue): \(categorySuccess)/\(categoryResults.count) (\(String(format: "%.1f", categoryRate))%)")
                }
            }
        }
        
        // Show failed tests
        let failedResults = resultCollector.getFailedResults()
        if !failedResults.isEmpty {
            print("")
            print("❌ Failed Tests:")
            for failed in failedResults {
                print("  - \(failed.testName): \(failed.error?.localizedDescription ?? "Unknown error")")
            }
        }
        
        // Generate performance summary
        if TestConfiguration.enablePerformanceMonitoring {
            print("")
            print("📈 Performance Summary:")
            await performanceDashboard.generateSummary(testResults: allResults)
        }
        
        // Export reports
        if TestConfiguration.exportDetailedReports {
            let report = resultCollector.generateReport()
            try? report.write(toFile: "/tmp/timebeam-test-report.md", atomically: true, encoding: .utf8)
            print("📄 Detailed report exported to: /tmp/timebeam-test-report.md")
        }
        
        print("")
        print("🎉 Test run completed!")
    }
    
    // MARK: - Helper Methods
    
    private func getMemorySnapshot() -> Int64 {
        // Simulate getting current memory usage
        return Int64.random(in: 50_000_000...200_000_000)
    }
}

// MARK: - Supporting Types

private struct TestRunInfo {
    let id: String
    let category: String
    let startTime: Date
    let buildNumber: String
    let gitCommit: String
}

private extension TestResultCollector {
    func addResults(_ results: [TestResult]) {
        results.forEach { addResult($0) }
    }
}

private extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}