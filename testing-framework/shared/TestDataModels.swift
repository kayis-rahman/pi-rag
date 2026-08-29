//
//  TestDataModels.swift
//  TimeBeam Testing Framework
//
//  Shared test data models and utilities for comprehensive testing
//

import Foundation

/// Test conflict scenario for multi-device sync testing
public struct TestConflictScenario {
    public let id: UUID
    public let name: String
    public let description: String
    public let deviceStates: [String: MockTimerState] // deviceId -> timerState
    public let actions: [TestConflictAction]
    public let expectedResolution: ConflictResolutionTestStrategy
    public let expectedOutcome: MockTimerState?
    public let metadata: [String: Any]
    
    public init(id: UUID = UUID(),
                name: String,
                description: String,
                deviceStates: [String: MockTimerState],
                actions: [TestConflictAction],
                expectedResolution: ConflictResolutionTestStrategy,
                expectedOutcome: MockTimerState? = nil,
                metadata: [String: Any] = [:]) {
        self.id = id
        self.name = name
        self.description = description
        self.deviceStates = deviceStates
        self.actions = actions
        self.expectedResolution = expectedResolution
        self.expectedOutcome = expectedOutcome
        self.metadata = metadata
    }
}

/// Test conflict action for scenario testing
public struct TestConflictAction {
    public let deviceId: String
    public let action: TimerAction
    public let timestamp: Date
    public let delay: TimeInterval? // Delay before action execution
    public let networkCondition: NetworkSimulationMode?
    
    public init(deviceId: String,
                action: TimerAction,
                timestamp: Date = Date(),
                delay: TimeInterval? = nil,
                networkCondition: NetworkSimulationMode? = nil) {
        self.deviceId = deviceId
        self.action = action
        self.timestamp = timestamp
        self.delay = delay
        self.networkCondition = networkCondition
    }
}

/// Test user journey for end-to-end workflow testing
public struct TestUserJourney {
    public let id: UUID
    public let name: String
    public let description: String
    public let steps: [TestJourneyStep]
    public let expectedStates: [String: MockTimerState] // stepId -> expectedState
    public let successCriteria: [TestSuccessCriterion]
    public let devices: [String] // device IDs involved
    
    public init(id: UUID = UUID(),
                name: String,
                description: String,
                steps: [TestJourneyStep],
                expectedStates: [String: MockTimerState] = [:],
                successCriteria: [TestSuccessCriterion] = [],
                devices: [String] = []) {
        self.id = id
        self.name = name
        self.description = description
        self.steps = steps
        self.expectedStates = expectedStates
        self.successCriteria = successCriteria
        self.devices = devices
    }
}

/// Test journey step for user workflow testing
public struct TestJourneyStep {
    public let id: String
    public let name: String
    public let deviceId: String
    public let action: TestJourneyAction
    public let expectedDuration: TimeInterval
    public let timeout: TimeInterval
    public let verificationSteps: [TestVerificationStep]
    
    public init(id: String,
                name: String,
                deviceId: String,
                action: TestJourneyAction,
                expectedDuration: TimeInterval,
                timeout: TimeInterval = TestConfiguration.defaultTimeout,
                verificationSteps: [TestVerificationStep] = []) {
        self.id = id
        self.name = name
        self.deviceId = deviceId
        self.action = action
        self.expectedDuration = expectedDuration
        self.timeout = timeout
        self.verificationSteps = verificationSteps
    }
}

/// Test journey action types
public enum TestJourneyAction {
    case timerAction(TimerAction)
    case appLaunch
    case appBackground
    case appTerminate
    case networkInterruption(TimeInterval)
    case deviceDisconnect
    case deviceReconnect
    case pushNotificationReceived(MockPushNotification)
    case userPreferenceChange(String, Any) // key, value
    case conflictResolutionChoice(String) // action choice
    case customAction(String, [String: Any]) // actionName, parameters
}

/// Test verification step
public struct TestVerificationStep {
    public let name: String
    public let deviceId: String?
    public let verificationType: TestVerificationType
    public let expectedValue: Any?
    public let tolerance: Any? // For range-based comparisons
    
    public init(name: String,
                deviceId: String? = nil,
                verificationType: TestVerificationType,
                expectedValue: Any? = nil,
                tolerance: Any? = nil) {
        self.name = name
        self.deviceId = deviceId
        self.verificationType = verificationType
        self.expectedValue = expectedValue
        self.tolerance = tolerance
    }
}

/// Test verification types
public enum TestVerificationType {
    case timerStateEquals
    case timerStateWithinRange
    case deviceConnected
    case deviceDisconnected
    case syncLatencyBelow
    case notificationReceived
    case databaseRecordExists
    case conflictResolved
    case customVerification(String) // verification name
}

/// Test success criteria for journey validation
public struct TestSuccessCriterion {
    public let name: String
    public let criterionType: TestCriterionType
    public let threshold: Any
    public let mandatory: Bool
    
    public init(name: String,
                criterionType: TestCriterionType,
                threshold: Any,
                mandatory: Bool = true) {
        self.name = name
        self.criterionType = criterionType
        self.threshold = threshold
        self.mandatory = mandatory
    }
}

/// Test criterion types
public enum TestCriterionType {
    case syncSuccessRateAbove(Double)
    case averageLatencyBelow(TimeInterval)
    case batteryUsageBelow(Double)
    case memoryUsageBelow(Int64)
    case conflictResolutionRateAbove(Double)
    case userJourneyCompletionTimeBelow(TimeInterval)
    case customCriterion(String, Any) // criterionName, threshold
}

/// Performance metrics collection for testing
public struct TestPerformanceMetrics {
    public let testID: String
    public let deviceID: String
    public let startTime: Date
    public let endTime: Date
    public let cpuMetrics: CPUMetrics
    public let memoryMetrics: MemoryMetrics
    public let networkMetrics: NetworkMetrics
    public let batteryMetrics: BatteryMetrics
    public let databaseMetrics: DatabaseMetrics
    
    public init(testID: String,
                deviceID: String,
                startTime: Date,
                endTime: Date,
                cpuMetrics: CPUMetrics = CPUMetrics(),
                memoryMetrics: MemoryMetrics = MemoryMetrics(),
                networkMetrics: NetworkMetrics = NetworkMetrics(),
                batteryMetrics: BatteryMetrics = BatteryMetrics(),
                databaseMetrics: DatabaseMetrics = DatabaseMetrics()) {
        self.testID = testID
        self.deviceID = deviceID
        self.startTime = startTime
        self.endTime = endTime
        self.cpuMetrics = cpuMetrics
        self.memoryMetrics = memoryMetrics
        self.networkMetrics = networkMetrics
        self.batteryMetrics = batteryMetrics
        self.databaseMetrics = databaseMetrics
    }
    
    public var duration: TimeInterval {
        return endTime.timeIntervalSince(startTime)
    }
}

/// CPU performance metrics
public struct CPUMetrics {
    public let averageUsage: Double
    public let peakUsage: Double
    public let samples: [CPUSample]
    
    public init(averageUsage: Double = 0.0, peakUsage: Double = 0.0, samples: [CPUSample] = []) {
        self.averageUsage = averageUsage
        self.peakUsage = peakUsage
        self.samples = samples
    }
}

/// CPU sample data point
public struct CPUSample {
    public let timestamp: Date
    public let usage: Double
    public let coreCount: Int
    
    public init(timestamp: Date = Date(), usage: Double = 0.0, coreCount: Int = 1) {
        self.timestamp = timestamp
        self.usage = usage
        self.coreCount = coreCount
    }
}

/// Memory performance metrics
public struct MemoryMetrics {
    public let baselineUsage: Int64
    public let peakUsage: Int64
    public let finalUsage: Int64
    public let averageUsage: Int64
    public let leaksDetected: Int
    
    public init(baselineUsage: Int64 = 0, peakUsage: Int64 = 0, finalUsage: Int64 = 0, averageUsage: Int64 = 0, leaksDetected: Int = 0) {
        self.baselineUsage = baselineUsage
        self.peakUsage = peakUsage
        self.finalUsage = finalUsage
        self.averageUsage = averageUsage
        self.leaksDetected = leaksDetected
    }
    
    public var memoryIncrease: Int64 {
        return finalUsage - baselineUsage
    }
}

/// Network performance metrics
public struct NetworkMetrics {
    public let totalRequests: Int
    public let successfulRequests: Int
    public let failedRequests: Int
    public let averageLatency: TimeInterval
    public let peakLatency: TimeInterval
    public let dataTransferred: Int64
    public let connectionErrors: Int
    
    public init(totalRequests: Int = 0,
                successfulRequests: Int = 0,
                failedRequests: Int = 0,
                averageLatency: TimeInterval = 0.0,
                peakLatency: TimeInterval = 0.0,
                dataTransferred: Int64 = 0,
                connectionErrors: Int = 0) {
        self.totalRequests = totalRequests
        self.successfulRequests = successfulRequests
        self.failedRequests = failedRequests
        self.averageLatency = averageLatency
        self.peakLatency = peakLatency
        self.dataTransferred = dataTransferred
        self.connectionErrors = connectionErrors
    }
    
    public var successRate: Double {
        guard totalRequests > 0 else { return 0.0 }
        return Double(successfulRequests) / Double(totalRequests)
    }
}

/// Battery performance metrics
public struct BatteryMetrics {
    public let initialLevel: Double
    public let finalLevel: Double
    public let drainRate: Double // percentage per hour
    public let isPowerConnected: Bool
    
    public init(initialLevel: Double = 100.0,
                finalLevel: Double = 100.0,
                drainRate: Double = 0.0,
                isPowerConnected: Bool = false) {
        self.initialLevel = initialLevel
        self.finalLevel = finalLevel
        self.drainRate = drainRate
        self.isPowerConnected = isPowerConnected
    }
    
    public var batteryDrain: Double {
        return initialLevel - finalLevel
    }
}

/// Database performance metrics
public struct DatabaseMetrics {
    public let totalQueries: Int
    public let readQueries: Int
    public let writeQueries: Int
    public let averageQueryTime: TimeInterval
    public let slowQueries: Int
    public let connectionPoolUsage: Double
    public let transactionsCommitted: Int
    public let transactionsRolledBack: Int
    
    public init(totalQueries: Int = 0,
                readQueries: Int = 0,
                writeQueries: Int = 0,
                averageQueryTime: TimeInterval = 0.0,
                slowQueries: Int = 0,
                connectionPoolUsage: Double = 0.0,
                transactionsCommitted: Int = 0,
                transactionsRolledBack: Int = 0) {
        self.totalQueries = totalQueries
        self.readQueries = readQueries
        self.writeQueries = writeQueries
        self.averageQueryTime = averageQueryTime
        self.slowQueries = slowQueries
        self.connectionPoolUsage = connectionPoolUsage
        self.transactionsCommitted = transactionsCommitted
        self.transactionsRolledBack = transactionsRolledBack
    }
    
    public var querySuccessRate: Double {
        guard totalQueries > 0 else { return 0.0 }
        return Double(totalQueries - slowQueries) / Double(totalQueries)
    }
}

/// Test result container
public struct TestResult {
    public let testName: String
    public let success: Bool
    public let duration: TimeInterval
    public let error: Error?
    public let metrics: TestPerformanceMetrics?
    public let attachments: [TestAttachment]
    public let metadata: [String: Any]
    
    public init(testName: String,
                success: Bool,
                duration: TimeInterval,
                error: Error? = nil,
                metrics: TestPerformanceMetrics? = nil,
                attachments: [TestAttachment] = [],
                metadata: [String: Any] = [:]) {
        self.testName = testName
        self.success = success
        self.duration = duration
        self.error = error
        self.metrics = metrics
        self.attachments = attachments
        self.metadata = metadata
    }
}

/// Test attachment for logs and screenshots
public struct TestAttachment {
    public let name: String
    public let type: TestAttachmentType
    public let data: Data
    public let timestamp: Date
    
    public init(name: String, type: TestAttachmentType, data: Data, timestamp: Date = Date()) {
        self.name = name
        self.type = type
        self.data = data
        self.timestamp = timestamp
    }
}

/// Test attachment types
public enum TestAttachmentType {
    case screenshot
    case log
    case networkLog
    case databaseLog
    case performanceData
    case custom(String)
}