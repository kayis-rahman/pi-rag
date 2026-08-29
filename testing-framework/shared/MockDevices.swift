//
//  MockDevices.swift
//  TimeBeam Testing Framework
//
//  Mock device implementations for multi-device testing scenarios
//

import Foundation

/// Protocol for mock device behavior in testing
public protocol MockDevice {
    var deviceConfig: MockDeviceConfig { get }
    var isConnected: Bool { get set }
    var lastSyncTimestamp: Date? { get set }
    var currentTimerState: MockTimerState? { get set }
    
    func simulateTimerAction(_ action: TimerAction)
    func simulateNetworkInterruption(duration: TimeInterval)
    func simulateHeartbeat()
    func receivePushNotification(_ notification: MockPushNotification)
}

/// Mock timer state for testing
public struct MockTimerState {
    public let phase: String
    public let remainingSeconds: Int
    public let isRunning: Bool
    public let workDuration: Int
    public let breakDuration: Int
    public let longBreakDuration: Int
    public let autoStartNextSession: Bool
    public let shortBreaksCompleted: Int
    public let timestamp: Date
    public let deviceId: String
    
    public init(phase: String = "work",
                remainingSeconds: Int = 1500,
                isRunning: Bool = false,
                workDuration: Int = 1500,
                breakDuration: Int = 300,
                longBreakDuration: Int = 900,
                autoStartNextSession: Bool = true,
                shortBreaksCompleted: Int = 0,
                timestamp: Date = Date(),
                deviceId: String) {
        self.phase = phase
        self.remainingSeconds = remainingSeconds
        self.isRunning = isRunning
        self.workDuration = workDuration
        self.breakDuration = breakDuration
        self.longBreakDuration = longBreakDuration
        self.autoStartNextSession = autoStartNextSession
        self.shortBreaksCompleted = shortBreaksCompleted
        self.timestamp = timestamp
        self.deviceId = deviceId
    }
}

/// Timer actions for testing
public enum TimerAction: String, CaseIterable {
    case start = "start"
    case pause = "pause"
    case reset = "reset"
    case skip = "skip"
    case complete = "complete"
}

/// Mock push notification for testing
public struct MockPushNotification {
    public let type: String
    public let title: String
    public let subtitle: String?
    public let body: String
    public let actions: [MockNotificationAction]
    public let priority: NotificationPriority
    public let timestamp: Date
    
    public init(type: String,
                title: String,
                subtitle: String? = nil,
                body: String,
                actions: [MockNotificationAction] = [],
                priority: NotificationPriority = .normal,
                timestamp: Date = Date()) {
        self.type = type
        self.title = title
        self.subtitle = subtitle
        self.body = body
        self.actions = actions
        self.priority = priority
        self.timestamp = timestamp
    }
}

/// Mock notification action for testing
public struct MockNotificationAction {
    public let id: String
    public let title: String
    public let isDestructive: Bool
    
    public init(id: String, title: String, isDestructive: Bool = false) {
        self.id = id
        self.title = title
        self.isDestructive = isDestructive
    }
}

/// Notification priority levels for testing
public enum NotificationPriority: String, CaseIterable {
    case low = "LOW"
    case normal = "NORMAL"
    case high = "HIGH"
}

/// Mock iOS Device implementation
public class MockiOSDevice: MockDevice {
    public let deviceConfig: MockDeviceConfig
    public var isConnected: Bool = true
    public var lastSyncTimestamp: Date?
    public var currentTimerState: MockTimerState?
    
    private var syncCallback: ((MockTimerState) -> Void)?
    private var notificationCallback: ((MockPushNotification) -> Void)?
    
    public init(config: MockDeviceConfig = TestConfiguration.MockDevices.iOSDevice) {
        self.deviceConfig = config
        self.currentTimerState = MockTimerState(deviceId: config.id)
    }
    
    public func simulateTimerAction(_ action: TimerAction) {
        guard isConnected else { return }
        
        let newState: MockTimerState
        switch action {
        case .start:
            newState = MockTimerState(
                phase: currentTimerState?.phase ?? "work",
                remainingSeconds: currentTimerState?.remainingSeconds ?? 1500,
                isRunning: true,
                deviceId: deviceConfig.id
            )
        case .pause:
            newState = MockTimerState(
                phase: currentTimerState?.phase ?? "work",
                remainingSeconds: currentTimerState?.remainingSeconds ?? 1500,
                isRunning: false,
                deviceId: deviceConfig.id
            )
        case .reset:
            newState = MockTimerState(
                phase: "work",
                remainingSeconds: 1500,
                isRunning: false,
                deviceId: deviceConfig.id
            )
        case .skip:
            let nextPhase = currentTimerState?.phase == "work" ? "break" : "work"
            newState = MockTimerState(
                phase: nextPhase,
                remainingSeconds: nextPhase == "work" ? 1500 : 300,
                isRunning: true,
                deviceId: deviceConfig.id
            )
        case .complete:
            let nextPhase = currentTimerState?.phase == "work" ? "break" : "work"
            newState = MockTimerState(
                phase: nextPhase,
                remainingSeconds: nextPhase == "work" ? 1500 : 300,
                isRunning: false,
                deviceId: deviceConfig.id
            )
        }
        
        currentTimerState = newState
        lastSyncTimestamp = Date()
        syncCallback?(newState)
    }
    
    public func simulateNetworkInterruption(duration: TimeInterval) {
        isConnected = false
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.isConnected = true
        }
    }
    
    public func simulateHeartbeat() {
        guard isConnected else { return }
        lastSyncTimestamp = Date()
    }
    
    public func receivePushNotification(_ notification: MockPushNotification) {
        guard isConnected else { return }
        notificationCallback?(notification)
    }
    
    public func onSync(_ callback: @escaping (MockTimerState) -> Void) {
        syncCallback = callback
    }
    
    public func onNotification(_ callback: @escaping (MockPushNotification) -> Void) {
        notificationCallback = callback
    }
}

/// Mock macOS Device implementation
public class MockmacOSDevice: MockDevice {
    public let deviceConfig: MockDeviceConfig
    public var isConnected: Bool = true
    public var lastSyncTimestamp: Date?
    public var currentTimerState: MockTimerState?
    
    private var syncCallback: ((MockTimerState) -> Void)?
    private var notificationCallback: ((MockPushNotification) -> Void)?
    
    public init(config: MockDeviceConfig = TestConfiguration.MockDevices.macOSDevice) {
        self.deviceConfig = config
        self.currentTimerState = MockTimerState(deviceId: config.id)
    }
    
    public func simulateTimerAction(_ action: TimerAction) {
        guard isConnected else { return }
        
        // macOS devices typically have longer work sessions
        let workDuration = 1800 // 30 minutes instead of 25
        
        let newState: MockTimerState
        switch action {
        case .start:
            newState = MockTimerState(
                phase: currentTimerState?.phase ?? "work",
                remainingSeconds: workDuration,
                isRunning: true,
                workDuration: workDuration,
                deviceId: deviceConfig.id
            )
        case .pause:
            newState = MockTimerState(
                phase: currentTimerState?.phase ?? "work",
                remainingSeconds: currentTimerState?.remainingSeconds ?? workDuration,
                isRunning: false,
                workDuration: workDuration,
                deviceId: deviceConfig.id
            )
        case .reset:
            newState = MockTimerState(
                phase: "work",
                remainingSeconds: workDuration,
                isRunning: false,
                workDuration: workDuration,
                deviceId: deviceConfig.id
            )
        case .skip:
            let nextPhase = currentTimerState?.phase == "work" ? "break" : "work"
            let breakDuration = nextPhase == "work" ? workDuration : 600 // 10 min breaks on macOS
            newState = MockTimerState(
                phase: nextPhase,
                remainingSeconds: breakDuration,
                isRunning: true,
                workDuration: workDuration,
                breakDuration: breakDuration,
                deviceId: deviceConfig.id
            )
        case .complete:
            let nextPhase = currentTimerState?.phase == "work" ? "break" : "work"
            let breakDuration = nextPhase == "work" ? workDuration : 600
            newState = MockTimerState(
                phase: nextPhase,
                remainingSeconds: breakDuration,
                isRunning: false,
                workDuration: workDuration,
                breakDuration: breakDuration,
                deviceId: deviceConfig.id
            )
        }
        
        currentTimerState = newState
        lastSyncTimestamp = Date()
        syncCallback?(newState)
    }
    
    public func simulateNetworkInterruption(duration: TimeInterval) {
        isConnected = false
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.isConnected = true
        }
    }
    
    public func simulateHeartbeat() {
        guard isConnected else { return }
        lastSyncTimestamp = Date()
    }
    
    public func receivePushNotification(_ notification: MockPushNotification) {
        guard isConnected else { return }
        notificationCallback?(notification)
    }
    
    public func onSync(_ callback: @escaping (MockTimerState) -> Void) {
        syncCallback = callback
    }
    
    public func onNotification(_ callback: @escaping (MockPushNotification) -> Void) {
        notificationCallback = callback
    }
}

/// Mock watchOS Device implementation
public class MockwatchOSDevice: MockDevice {
    public let deviceConfig: MockDeviceConfig
    public var isConnected: Bool = true
    public var lastSyncTimestamp: Date?
    public var currentTimerState: MockTimerState?
    
    private var syncCallback: ((MockTimerState) -> Void)?
    private var notificationCallback: ((MockPushNotification) -> Void)?
    
    public init(config: MockDeviceConfig = TestConfiguration.MockDevices.watchOSDevice) {
        self.deviceConfig = config
        self.currentTimerState = MockTimerState(deviceId: config.id)
    }
    
    public func simulateTimerAction(_ action: TimerAction) {
        guard isConnected else { return }
        
        // watchOS devices have simplified interactions
        let newState: MockTimerState
        switch action {
        case .start:
            newState = MockTimerState(
                phase: currentTimerState?.phase ?? "work",
                remainingSeconds: currentTimerState?.remainingSeconds ?? 1500,
                isRunning: true,
                deviceId: deviceConfig.id
            )
        case .pause:
            newState = MockTimerState(
                phase: currentTimerState?.phase ?? "work",
                remainingSeconds: currentTimerState?.remainingSeconds ?? 1500,
                isRunning: false,
                deviceId: deviceConfig.id
            )
        case .reset:
            newState = MockTimerState(
                phase: "work",
                remainingSeconds: 1500,
                isRunning: false,
                deviceId: deviceConfig.id
            )
        case .skip, .complete:
            // On watch, skip and complete both just move to next phase
            let nextPhase = currentTimerState?.phase == "work" ? "break" : "work"
            newState = MockTimerState(
                phase: nextPhase,
                remainingSeconds: nextPhase == "work" ? 1500 : 300,
                isRunning: true,
                deviceId: deviceConfig.id
            )
        }
        
        currentTimerState = newState
        lastSyncTimestamp = Date()
        syncCallback?(newState)
    }
    
    public func simulateNetworkInterruption(duration: TimeInterval) {
        isConnected = false
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.isConnected = true
        }
    }
    
    public func simulateHeartbeat() {
        guard isConnected else { return }
        // watchOS sends more frequent heartbeats due to phone dependency
        lastSyncTimestamp = Date()
    }
    
    public func receivePushNotification(_ notification: MockPushNotification) {
        guard isConnected else { return }
        // watchOS only receives high priority notifications
        if notification.priority == .high {
            notificationCallback?(notification)
        }
    }
    
    public func onSync(_ callback: @escaping (MockTimerState) -> Void) {
        syncCallback = callback
    }
    
    public func onNotification(_ callback: @escaping (MockPushNotification) -> Void) {
        notificationCallback = callback
    }
}

/// Mock device factory for creating different device types
public class MockDeviceFactory {
    public static func createDevice(type: String, config: MockDeviceConfig? = nil) -> MockDevice {
        let deviceConfig = config ?? defaultConfig(for: type)
        
        switch type.lowercased() {
        case "ios":
            return MockiOSDevice(config: deviceConfig)
        case "macos":
            return MockmacOSDevice(config: deviceConfig)
        case "watchos":
            return MockwatchOSDevice(config: deviceConfig)
        default:
            return MockiOSDevice(config: deviceConfig)
        }
    }
    
    private static func defaultConfig(for type: String) -> MockDeviceConfig {
        switch type.lowercased() {
        case "ios":
            return TestConfiguration.MockDevices.iOSDevice
        case "macos":
            return TestConfiguration.MockDevices.macOSDevice
        case "watchos":
            return TestConfiguration.MockDevices.watchOSDevice
        default:
            return TestConfiguration.MockDevices.iOSDevice
        }
    }
}