import Foundation
import Combine

/**
 * iOS Manager for Timer State Events using Server-Sent Events
 * Optimized for battery efficiency and real-time updates
 */
class TimerEventManager {
    private var eventSource: EventSource?
    private var lastEventId: String?
    private let userId: UUID
    private let apiClient: ApiClient
    
    private var isConnected = false
    private var deviceActivityManager: DeviceActivityManager?
    
    init(userId: UUID) {
        self.userId = userId
        self.apiClient = ApiClient()
        self.deviceActivityManager = DeviceActivityManager()
    }
    
    // MARK: - Public Interface
    
    /**
     * Connect to timer events using SSE
     */
    func connectToTimerEvents() {
        guard let userId = self.userId else { return }
        
        var url = URL(string: "\(apiClient.baseURL)/api/events/timer/\(userId)")
        
        if let lastEventId = self.lastEventId {
            url.append(queryItems: [
                URLQueryItem(name: "Last-Event-ID", value: lastEventId)
            ])
        }
        
        print("🔔 Connecting to SSE endpoint: \(url)")
        
        eventSource = EventSource(url: url)
        eventSource?.onOpen { [weak self] in
            print("✅ SSE Connection established for timer events")
            self.isConnected = true
            self.deviceActivityManager?.markDeviceAsActive()
        }
        
        eventSource?.onMessage { [weak self] in
            if let data = $0,
               let event = parseTimerEvent(from: data) {
                print("📱 Received timer event: \(event)")
                self.handleTimerEvent(event)
            }
        }
        
        eventSource?.onError { [weak self] in
            print("❌ SSE Error: \($0)")
            scheduleReconnection()
        }
    }
    
    /**
     * Disconnect from SSE
     */
    func disconnectFromTimerEvents() {
        self.isConnected = false
        self.eventSource?.close()
        self.eventSource = nil
        self.deviceActivityManager?.markDeviceAsInactive()
        print("🔌 Disconnected from SSE endpoint")
    }
    
    // MARK: - Private Implementation
    
    /**
     * Parse timer event from SSE data
     */
    private func parseTimerEvent(from data: String) -> TimerEvent? {
        guard let jsonData = data.data(using: .utf8) else { return nil }
        
        do {
            let event = try JSONDecoder().decode(TimerEvent.self, from: jsonData)
            DispatchQueue.main.async {
                self.lastEventId = event.eventId
                self.applyEventToTimer(event)
            }
            return event
        } catch {
            print("⚠️ Failed to parse timer event: \(error)")
            return nil
        }
    }
    
    /**
     * Apply timer event to local timer state
     */
    private func applyEventToTimer(_ event: TimerEvent) {
        switch event.type {
        case .stateChange:
            if let newState = event.newState {
                DispatchQueue.main.async {
                    // Update timer display with state change
                    self.updateTimerDisplay(
                        remaining: newState.remainingSeconds,
                        phase: newState.phase,
                        isRunning: newState.isRunning
                    )
                    
                    // Update device activity with smart state management
                    self.deviceActivityManager?.updateDeviceState(from: event.previousState, to: newState)
                }
            }
            
        case .tick:
            DispatchQueue.main.async {
                self.updateTimerDisplay(
                    remaining: event.remainingSeconds,
                        phase: event.phase
                    )
            }
            
        case .action:
            DispatchQueue.main.async {
                if let action = event.action {
                    self.applyTimerAction(action)
                }
            }
        }
    }
    
    /**
     * Apply timer action locally
     */
    private func applyTimerAction(_ action: String) {
        print("🔄 Applying timer action: \(action)")
        // This will trigger local timer state change and sync via event system
        NotificationCenter.default.post(
            name: "TimerActionReceived",
            object: ["action": action],
            userInfo: ["userId": self.userId.uuidString]
        )
    }
    
    /**
     * Update timer display UI
     */
    private func updateTimerDisplay(remaining: Int, phase: String, isRunning: Bool) {
        print("🎯 Updating timer display: \(remaining)s, phase: \(phase), running: \(isRunning)")
        // This would update the actual UI components
        NotificationCenter.default.post(
            name: "TimerStateUpdated",
            object: [
                "remaining": remaining,
                "phase": phase,
                "isRunning": isRunning,
                "userId": self.userId.uuidString
            ]
        )
    }
    
    /**
     * Handle connection errors with exponential backoff
     */
    private func scheduleReconnection() {
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) { [weak self] in
            print("🔄 Attempting to reconnect to SSE...")
            connectToTimerEvents()
        }
    }
    
    /**
     * Handle app lifecycle events
     */
    func applicationDidBecomeActive() {
        print("📱 App became active - connecting to SSE")
        connectToTimerEvents()
    }
    
    func applicationDidBecomeInactive() {
        print("🔌 App became inactive - disconnecting from SSE")
        disconnectFromTimerEvents()
    }
}

/**
 * SSE Timer Event Model
 */
struct TimerEvent: Codable {
    let type: EventType
    let eventId: String
    let timestamp: Date
    let newState: TimerStateDto?
    let previousState: TimerStateDto?
    let deviceId: String
    let remainingSeconds: Int
    let phase: String
}

enum EventType: String, Codable {
    case stateChange = "STATE_CHANGE"
    case tick = "TICK"
    case action = "ACTION"
}

/**
 * Local timer state for iOS
 */
struct LocalTimerState {
    var remainingSeconds: Int
    var phase: String
    var isRunning: Bool
    var lastEventTime: Date?
}