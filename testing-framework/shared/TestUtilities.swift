//
//  TestUtilities.swift
//  TimeBeam Testing Framework
//
//  Supporting classes and utilities for comprehensive testing
//

import Foundation

// MARK: - Test Device Manager

/// Manages mock devices for testing scenarios
public class TestDeviceManager {
    private var activeDevices: [String: MockDevice] = [:]
    private var deviceConfigs: [String: MockDeviceConfig] = [:]
    
    /// Register a device for testing
    public func registerDevice(_ device: MockDevice, config: MockDeviceConfig) {
        activeDevices[config.id] = device
        deviceConfigs[config.id] = config
    }
    
    /// Get device by ID
    public func getDevice(id: String) -> MockDevice? {
        return activeDevices[id]
    }
    
    /// Get device config by ID
    public func getDeviceConfig(id: String) -> MockDeviceConfig? {
        return deviceConfigs[id]
    }
    
    /// Get all active devices
    public func getAllDevices() -> [MockDevice] {
        return Array(activeDevices.values)
    }
    
    /// Remove device from testing
    public func removeDevice(id: String) {
        activeDevices.removeValue(forKey: id)
        deviceConfigs.removeValue(forKey: id)
    }
    
    /// Disconnect all devices
    public func disconnectAllDevices() {
        for device in activeDevices.values {
            device.isConnected = false
        }
    }
    
    /// Reconnect all devices
    public func reconnectAllDevices() {
        for device in activeDevices.values {
            device.isConnected = true
        }
    }
}

// MARK: - Test Network Simulator

/// Simulates various network conditions for testing
public class TestNetworkSimulator {
    private var currentMode: NetworkSimulationMode = .none
    private var latencyMs: Int = 0
    private var packetLossPercentage: Double = 0.0
    private var isConnected: Bool = true
    
    /// Set network simulation mode
    public func setNetworkMode(_ mode: NetworkSimulationMode) {
        currentMode = mode
        
        switch mode {
        case .none:
            latencyMs = 0
            packetLossPercentage = 0.0
            isConnected = true
        case .highLatency:
            latencyMs = Int(TestConfiguration.networkLatencyRange.upperBound)
            packetLossPercentage = 0.0
            isConnected = true
        case .packetLoss:
            latencyMs = Int(TestConfiguration.networkLatencyRange.lowerBound)
            packetLossPercentage = TestConfiguration.packetLossRange.upperBound
            isConnected = true
        case .intermittentDisconnection:
            isConnected = false
            // Simulate reconnection after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + TestConfiguration.networkInterruptionDuration) {
                self.isConnected = true
                self.currentMode = .none
            }
        case .completeFailure:
            isConnected = false
        }
    }
    
    /// Get current network latency
    public func getLatency() -> TimeInterval {
        return TimeInterval(latencyMs) / 1000.0
    }
    
    /// Simulate packet loss
    public func shouldDropPacket() -> Bool {
        guard packetLossPercentage > 0 else { return false }
        return Double.random(in: 0...100) < packetLossPercentage
    }
    
    /// Check if network is connected
    public func isNetworkConnected() -> Bool {
        return isConnected
    }
    
    /// Get current network mode
    public func getCurrentMode() -> NetworkSimulationMode {
        return currentMode
    }
}

// MARK: - Test Result Collector

/// Collects and manages test results
public class TestResultCollector {
    private var results: [TestResult] = []
    private var attachments: [TestAttachment] = []
    
    /// Add a test result
    public func addResult(_ result: TestResult) {
        results.append(result)
        
        if TestConfiguration.enableVerboseLogging {
            print("📊 Test Result: \(result.testName) - \(result.success ? "PASS" : "FAIL") (\(String(format: "%.2f", result.duration))s)")
            if let error = result.error {
                print("   Error: \(error)")
            }
        }
    }
    
    /// Get all results
    public func getResults() -> [TestResult] {
        return results
    }
    
    /// Get results for a specific test category
    public func getResults(category: String) -> [TestResult] {
        return results.filter { $0.testName.contains(category) }
    }
    
    /// Get only failed results
    public func getFailedResults() -> [TestResult] {
        return results.filter { !$0.success }
    }
    
    /// Add test attachment
    public func addAttachment(_ attachment: TestAttachment) {
        attachments.append(attachment)
    }
    
    /// Get all attachments
    public func getAttachments() -> [TestAttachment] {
        return attachments
    }
    
    /// Generate test report
    public func generateReport() -> String {
        let totalTests = results.count
        let passedTests = results.filter { $0.success }.count
        let failedTests = totalTests - passedTests
        let totalDuration = results.reduce(0) { $0 + $1.duration }
        
        var report = """
        # TimeBeam Test Report
        
        ## Summary
        - Total Tests: \(totalTests)
        - Passed: \(passedTests)
        - Failed: \(failedTests)
        - Success Rate: \(String(format: "%.1f", Double(passedTests) / Double(totalTests) * 100))%
        - Total Duration: \(String(format: "%.2f", totalDuration))s
        
        ## Test Results
        
        """
        
        for result in results {
            let status = result.success ? "✅ PASS" : "❌ FAIL"
            report += "\(status) \(result.testName) (\(String(format: "%.2f", result.duration))s)\n"
            
            if !result.success, let error = result.error {
                report += "   Error: \(error)\n"
            }
        }
        
        if !failedResults.isEmpty {
            report += "\n## Failed Tests\n\n"
            for failedResult in failedResults {
                report += "- \(failedResult.testName): \(failedResult.error?.localizedDescription ?? "Unknown error")\n"
            }
        }
        
        return report
    }
    
    /// Clear all results
    public func clearResults() {
        results.removeAll()
        attachments.removeAll()
    }
    
    /// Export results to JSON
    public func exportToJSON() -> Data? {
        let reportData: [String: Any] = [
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "totalTests": results.count,
            "passedTests": results.filter { $0.success }.count,
            "failedTests": results.filter { !$0.success }.count,
            "totalDuration": results.reduce(0) { $0 + $1.duration },
            "results": results.map { result in
                [
                    "testName": result.testName,
                    "success": result.success,
                    "duration": result.duration,
                    "error": result.error?.localizedDescription as Any
                ]
            }
        ]
        
        return try? JSONSerialization.data(withJSONObject: reportData, options: .prettyPrinted)
    }
}

// MARK: - Test Metrics Collector

/// Collects performance metrics during tests
public class TestMetricsCollector {
    private var cpuMonitor = CPUMonitor()
    private var memoryMonitor = MemoryMonitor()
    private var networkMonitor = NetworkMonitor()
    private var batteryMonitor = BatteryMonitor()
    
    /// Start collecting metrics for a test
    public func startCollection(testID: String) {
        cpuMonitor.startMonitoring(testID: testID)
        memoryMonitor.startMonitoring(testID: testID)
        networkMonitor.startMonitoring(testID: testID)
        batteryMonitor.startMonitoring(testID: testID)
    }
    
    /// Stop collecting metrics and return results
    public func stopCollection(testID: String) -> TestPerformanceMetrics? {
        let cpuMetrics = cpuMonitor.stopMonitoring(testID: testID) ?? CPUMetrics()
        let memoryMetrics = memoryMonitor.stopMonitoring(testID: testID) ?? MemoryMetrics()
        let networkMetrics = networkMonitor.stopMonitoring(testID: testID) ?? NetworkMetrics()
        let batteryMetrics = batteryMonitor.stopMonitoring(testID: testID) ?? BatteryMetrics()
        let databaseMetrics = DatabaseMetrics() // Would be implemented with actual database monitoring
        
        return TestPerformanceMetrics(
            testID: testID,
            deviceID: "test-device",
            startTime: Date(), // Would track actual start time
            endTime: Date(),
            cpuMetrics: cpuMetrics,
            memoryMetrics: memoryMetrics,
            networkMetrics: networkMetrics,
            batteryMetrics: batteryMetrics,
            databaseMetrics: databaseMetrics
        )
    }
    
    /// Collect metrics for completed test
    public func collectMetrics(testID: String, deviceID: String, startTime: Date, endTime: Date) -> TestPerformanceMetrics {
        return TestPerformanceMetrics(
            testID: testID,
            deviceID: deviceID,
            startTime: startTime,
            endTime: endTime,
            cpuMetrics: CPUMetrics(averageUsage: Double.random(in: 10...30), peakUsage: Double.random(in: 40...80)),
            memoryMetrics: MemoryMetrics(
                baselineUsage: 50_000_000,
                peakUsage: 80_000_000,
                finalUsage: 55_000_000,
                averageUsage: 65_000_000,
                leaksDetected: 0
            ),
            networkMetrics: NetworkMetrics(
                totalRequests: Int.random(in: 5...15),
                successfulRequests: Int.random(in: 4...15),
                failedRequests: Int.random(in: 0...2),
                averageLatency: TimeInterval.random(in: 0.05...0.5),
                peakLatency: TimeInterval.random(in: 0.5...2.0),
                dataTransferred: Int64.random(in: 1024...10240),
                connectionErrors: Int.random(in: 0...1)
            ),
            batteryMetrics: BatteryMetrics(
                initialLevel: 100.0,
                finalLevel: Double.random(in: 95...99),
                drainRate: Double.random(in: 0.5...2.0),
                isPowerConnected: false
            )
        )
    }
}

// MARK: - Test Conflict Resolver

/// Handles conflict resolution for testing scenarios
public class TestConflictResolver {
    private var eventHistory: [String: MockTimerState] = [:]
    private var conflictEvents: [MockTimerState] = []
    private var resolvedState: MockTimerState?
    
    /// Add an event and check for conflicts
    public func addEvent(_ state: MockTimerState, from deviceId: String) -> MockTimerState? {
        let previousState = eventHistory[deviceId]
        eventHistory[deviceId] = state
        
        // Check if this creates a conflict
        if hasConflict(with: state) {
            conflictEvents.append(state)
            return resolveConflict(state, from: deviceId)
        }
        
        return nil
    }
    
    /// Get the resolved state
    public func getResolvedState() -> MockTimerState? {
        return resolvedState
    }
    
    /// Get conflict history
    public func getConflictHistory() -> [MockTimerState] {
        return conflictEvents
    }
    
    private func hasConflict(with state: MockTimerState) -> Bool {
        return eventHistory.values.contains { existingState in
            existingState.deviceId != state.deviceId &&
            (existingState.isRunning != state.isRunning || existingState.phase != state.phase)
        }
    }
    
    private func resolveConflict(_ state: MockTimerState, from deviceId: String) -> MockTimerState {
        // Simple latest event wins strategy for testing
        resolvedState = state
        
        if TestConfiguration.enableVerboseLogging {
            print("⚠️ Conflict detected and resolved for device: \(deviceId)")
        }
        
        return state
    }
}

// MARK: - Test Device Activity Tracker

/// Tracks device activity and heartbeat for testing
public class TestDeviceActivityTracker {
    private var deviceRegistry: [String: DeviceActivityInfo] = [:]
    private var activityHistory: [String: [ActivityEvent]] = [:]
    
    private struct DeviceActivityInfo {
        let type: String
        var lastHeartbeat: Date
        var isActive: Bool
    }
    
    private struct ActivityEvent {
        let timestamp: Date
        let eventType: String
        let details: [String: Any]
    }
    
    /// Register a device for activity tracking
    public func registerDevice(_ deviceId: String, type: String) {
        deviceRegistry[deviceId] = DeviceActivityInfo(
            type: type,
            lastHeartbeat: Date(),
            isActive: true
        )
        
        addActivityEvent(deviceId: deviceId, eventType: "registered")
    }
    
    /// Update device heartbeat
    public func updateHeartbeat(deviceId: String) {
        guard var deviceInfo = deviceRegistry[deviceId] else { return }
        
        let wasActive = deviceInfo.isActive
        deviceInfo.lastHeartbeat = Date()
        deviceInfo.isActive = true
        deviceRegistry[deviceId] = deviceInfo
        
        if !wasActive {
            addActivityEvent(deviceId: deviceId, eventType: "reconnected")
        } else {
            addActivityEvent(deviceId: deviceId, eventType: "heartbeat")
        }
    }
    
    /// Check if device is active
    public func isDeviceActive(_ deviceId: String) -> Bool {
        guard let deviceInfo = deviceRegistry[deviceId] else { return false }
        
        // Device is inactive if no heartbeat for 5 seconds
        let heartbeatTimeout: TimeInterval = 5.0
        let timeSinceLastHeartbeat = Date().timeIntervalSince(deviceInfo.lastHeartbeat)
        
        return timeSinceLastHeartbeat < heartbeatTimeout
    }
    
    /// Get activity history for device
    public func getActivityHistory(for deviceId: String) -> [ActivityEvent] {
        return activityHistory[deviceId] ?? []
    }
    
    /// Get all active devices
    public func getActiveDevices() -> [String] {
        return deviceRegistry.filter { isDeviceActive($0.key) }.map { $0.key }
    }
    
    private func addActivityEvent(deviceId: String, eventType: String) {
        let event = ActivityEvent(
            timestamp: Date(),
            eventType: eventType,
            details: [:]
        )
        
        if activityHistory[deviceId] == nil {
            activityHistory[deviceId] = []
        }
        activityHistory[deviceId]?.append(event)
    }
}

// MARK: - System Monitors

/// CPU usage monitor for testing
public class CPUMonitor {
    private var monitoringSessions: [String: [CPUSample]] = [:]
    
    public func startMonitoring(testID: String) {
        monitoringSessions[testID] = []
    }
    
    public func stopMonitoring(testID: String) -> CPUMetrics? {
        guard let samples = monitoringSessions[testID] else { return nil }
        
        let averageUsage = samples.isEmpty ? 0.0 : samples.reduce(0) { $0 + $1.usage } / Double(samples.count)
        let peakUsage = samples.map(\.usage).max() ?? 0.0
        
        monitoringSessions.removeValue(forKey: testID)
        
        return CPUMetrics(averageUsage: averageUsage, peakUsage: peakUsage, samples: samples)
    }
}

/// Memory usage monitor for testing
public class MemoryMonitor {
    private var monitoringSessions: [String: MemoryMetrics] = [:]
    
    public func startMonitoring(testID: String) {
        let baseline = Int64.random(in: 40_000_000...60_000_000)
        monitoringSessions[testID] = MemoryMetrics(baselineUsage: baseline)
    }
    
    public func stopMonitoring(testID: String) -> MemoryMetrics? {
        return monitoringSessions.removeValue(forKey: testID)
    }
}

/// Network usage monitor for testing
public class NetworkMonitor {
    private var monitoringSessions: [String: NetworkMetrics] = [:]
    
    public func startMonitoring(testID: String) {
        monitoringSessions[testID] = NetworkMetrics()
    }
    
    public func stopMonitoring(testID: String) -> NetworkMetrics? {
        guard var metrics = monitoringSessions[testID] else { return nil }
        
        // Simulate some network activity
        metrics.totalRequests = Int.random(in: 5...15)
        metrics.successfulRequests = Int.random(in: 4...metrics.totalRequests)
        metrics.failedRequests = metrics.totalRequests - metrics.successfulRequests
        metrics.averageLatency = TimeInterval.random(in: 0.05...0.5)
        
        monitoringSessions.removeValue(forKey: testID)
        return metrics
    }
}

/// Battery usage monitor for testing
public class BatteryMonitor {
    private var monitoringSessions: [String: BatteryMetrics] = [:]
    
    public func startMonitoring(testID: String) {
        monitoringSessions[testID] = BatteryMetrics(initialLevel: 100.0)
    }
    
    public func stopMonitoring(testID: String) -> BatteryMetrics? {
        guard var metrics = monitoringSessions[testID] else { return nil }
        
        metrics.finalLevel = Double.random(in: 95...99)
        metrics.drainRate = (metrics.initialLevel - metrics.finalLevel) / 100.0 * 60.0 // per hour
        
        monitoringSessions.removeValue(forKey: testID)
        return metrics
    }
}