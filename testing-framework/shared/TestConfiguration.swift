//
//  TestConfiguration.swift
//  TimeBeam Testing Framework
//
//  Centralized configuration for all testing scenarios
//

import Foundation

/// Centralized test configuration for the TimeBeam testing framework
public struct TestConfiguration {
    
    // MARK: - Backend Configuration
    
    /// Base URL for the TimeBeam backend API
    public static let backendURL = "http://localhost:8080"
    
    /// E2E testing backend URL (can be overridden via environment)
    public static let e2eBackendURL = ProcessInfo.processInfo.environment["E2E_BACKEND_URL"] ?? backendURL
    
    // MARK: - Test User Configuration
    
    /// Default test user email for E2E tests
    public static let testUserEmail = "test@timebeam.app"
    
    /// Default test user password for E2E tests  
    public static let testUserPassword = "testpassword123"
    
    // MARK: - Timeout Configuration
    
    /// Quick timeout for simple operations (2 seconds)
    public static let quickTimeout: TimeInterval = 2.0
    
    /// Default timeout for standard operations (10 seconds)
    public static let defaultTimeout: TimeInterval = 10.0
    
    /// Extended timeout for complex operations (30 seconds)
    public static let extendedTimeout: TimeInterval = 30.0
    
    /// Maximum timeout for network operations (60 seconds)
    public static let networkTimeout: TimeInterval = 60.0
    
    // MARK: - Mock Device Configuration
    
    /// Mock device configurations for multi-device testing
    public struct MockDevices {
        public static let iOSDevice = MockDeviceConfig(
            id: "test-ios-device-uuid",
            name: "Test iPhone",
            type: "ios",
            platformVersion: "18.0",
            appVersion: "1.0.0"
        )
        
        public static let macOSDevice = MockDeviceConfig(
            id: "test-macos-device-uuid", 
            name: "Test MacBook",
            type: "macos",
            platformVersion: "15.0",
            appVersion: "1.0.0"
        )
        
        public static let watchOSDevice = MockDeviceConfig(
            id: "test-watchos-device-uuid",
            name: "Test Apple Watch", 
            type: "watchos",
            platformVersion: "11.0",
            appVersion: "1.0.0"
        )
    }
    
    // MARK: - Performance Thresholds
    
    /// Maximum acceptable sync latency in milliseconds
    public static let maxSyncLatencyMs = 500
    
    /// Maximum acceptable memory usage increase in MB
    public static let maxMemoryIncreaseMB = 50
    
    /// Maximum acceptable battery drain percentage per hour
    public static let maxBatteryDrainPerHour: Double = 5.0
    
    /// Minimum acceptable sync success rate percentage
    public static let minSyncSuccessRate: Double = 95.0
    
    // MARK: - Concurrency Testing
    
    /// Number of concurrent devices for stress testing
    public static let concurrentDeviceCount = 10
    
    /// Number of simultaneous actions for concurrency tests
    public static let simultaneousActionCount = 50
    
    /// Duration for stress tests in seconds
    public static let stressTestDuration: TimeInterval = 300.0
    
    // MARK: - Network Simulation
    
    /// Simulated network latency range in milliseconds
    public static let networkLatencyRange = ClosedRange(uncheckedBounds: (lower: 50, upper: 500))
    
    /// Simulated packet loss percentage range
    public static let packetLossRange = ClosedRange(uncheckedBounds: (lower: 0.0, upper: 10.0))
    
    /// Network interruption duration for recovery tests
    public static let networkInterruptionDuration: TimeInterval = 10.0
    
    // MARK: - Data Generation
    
    /// Number of test timer states to generate
    public static let testTimerStateCount = 100
    
    /// Number of test conflict scenarios to generate
    public static let testConflictScenarioCount = 50
    
    /// Number of test user journeys to generate
    public static let testUserJourneyCount = 20
    
    // MARK: - Logging and Debugging
    
    /// Enable verbose debug logging in tests
    public static let enableVerboseLogging = ProcessInfo.processInfo.environment["TEST_VERBOSE"] == "true"
    
    /// Enable performance monitoring in tests
    public static let enablePerformanceMonitoring = ProcessInfo.processInfo.environment["TEST_PERFORMANCE"] == "true"
    
    /// Export detailed test reports
    public static let exportDetailedReports = ProcessInfo.processInfo.environment["TEST_REPORTS"] == "true"
    
    // MARK: - CI/CD Configuration
    
    /// Test run identifier for CI/CD tracking
    public static var testRunID: String {
        return ProcessInfo.processInfo.environment["TEST_RUN_ID"] ?? UUID().uuidString
    }
    
    /// Build number for test correlation
    public static var buildNumber: String {
        return ProcessInfo.processInfo.environment["BUILD_NUMBER"] ?? "local"
    }
    
    /// Git commit SHA for test correlation
    public static var gitCommitSHA: String {
        return ProcessInfo.processInfo.environment["GIT_COMMIT"] ?? "unknown"
    }
}

/// Mock device configuration structure
public struct MockDeviceConfig {
    public let id: String
    public let name: String
    public let type: String
    public let platformVersion: String
    public let appVersion: String
}

/// Conflict resolution strategies for testing
public enum ConflictResolutionTestStrategy: String, CaseIterable {
    case latestEventWins = "LATEST_EVENT_WINS"
    case devicePriority = "DEVICE_PRIORITY" 
    case userChoice = "USER_CHOICE"
    case timeBased = "TIME_BASED"
}

/// Network simulation modes for testing
public enum NetworkSimulationMode: String, CaseIterable {
    case none = "NONE"
    case highLatency = "HIGH_LATENCY"
    case packetLoss = "PACKET_LOSS"
    case intermittentDisconnection = "INTERMITTENT_DISCONNECTION"
    case completeFailure = "COMPLETE_FAILURE"
}

/// Performance test metrics collection configuration
public struct PerformanceMetricsConfig {
    public let collectCPUMetrics = true
    public let collectMemoryMetrics = true
    public let collectNetworkMetrics = true
    public let collectBatteryMetrics = true
    public let collectDatabaseMetrics = true
    public let samplingIntervalMs = 100
    public let exportFormat = "json"
}

/// Test report configuration
public struct TestReportConfig {
    public let includeStackTraces = true
    public let includeDeviceLogs = true
    public let includeNetworkLogs = true
    public let includePerformanceMetrics = true
    public let exportFormat = "html"
    public let compressReports = true
}