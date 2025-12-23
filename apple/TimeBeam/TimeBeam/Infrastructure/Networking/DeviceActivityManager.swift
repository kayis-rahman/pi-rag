import Foundation
import Combine

/**
 * macOS Manager for Timer State Events using WebSocket
 * Real-time bidirectional sync with iOS SSE client
 */
@MainActor
class TimerWebSocketManager: ObservableObject {
    private var webSocketTask: URLSessionWebSocketTask?
    private var isConnected = false
    
    @Published var currentTimerState: LocalTimerState = LocalTimerState(remaining: 0, phase: "WORK", isRunning: false)
    
    private let apiClient: ApiClient
    private var deviceActivityManager: DeviceActivityManager?
    
    init(userId: UUID) async {
        self.userId = userId
        self.apiClient = await ApiClient()
        self.deviceActivityManager = DeviceActivityManager()
    }
    
    /**
     * Connect to WebSocket for real-time timer sync
     */
    func connectToTimerSync() async {
        guard let userId = self.userId else { return }
        
        var url = URL(string: "\(apiClient.baseURL)/api/timer/ws/\(userId)")
        
        var request = URLRequest(url: url)
        
        // Add access token if available
        if let token = apiClient.getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        request.timeoutInterval = 30
        
        print("🔗 Connecting to WebSocket for real-time sync...")
        
        webSocketTask = URLSession.shared.webSocketTask(with: request)
        webSocketTask?.resume()
        webSocketTask?.delegate = self
        
        self.isConnected = true
        await MainActor.run {
            self.deviceActivityManager?.markDeviceAsActive()
            print("✅ WebSocket connected for real-time sync")
        }
    }
    
    /**
     * Disconnect from WebSocket
     */
    func disconnectFromTimerSync() {
        webSocketTask?.cancel()
        webSocketTask = nil
        self.isConnected = false
        
        await MainActor.run {
            self.deviceActivityManager?.markDeviceAsInactive()
            print("🔌 Disconnected from WebSocket")
        }
    }
    
    /**
     * Send timer action to server (and broadcast to other devices)
     */
    func sendTimerAction(_ action: String) async {
        guard self.isConnected else { 
            print("⚠️ Not connected to WebSocket")
            return
        }
        
        let event = TimerSyncEvent(
            type: "action",
            action: action,
            timestamp: Date(),
            deviceId: await self.deviceActivityManager?.getDeviceId() ?? "unknown"
        )
        
        do {
            let jsonData = try JSONEncoder().encode(event)
            guard let jsonString = String(data: jsonData, encoding: .utf8) else { return }
            
            webSocketTask?.send(.string(jsonString))
            print("🔄 Sent timer action: \(action)")
        } catch {
            print("⚠️ Failed to send timer action: \(error)")
        }
    }
    
    /**
     * Handle incoming WebSocket messages
     */
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, 
                    didOpenWithProtocol protocol: String?) {
        guard let userId = self.userId else { return }
        
        print("✅ WebSocket connected")
        self.isConnected = true
        await MainActor.run {
            self.deviceActivityManager?.markDeviceAsActive()
        }
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, 
                   didReceiveMessageWith string: String) {
        guard let userId = self.userId else { return }
        
        guard let data = string.data(using: .utf8) else { return }
        
        do {
            let event = try JSONDecoder().decode(TimerSyncEvent.self, from: data)
            await MainActor.run {
                await self.handleSyncEvent(event)
            }
        } catch {
            print("⚠️ Failed to decode WebSocket message: \(error)")
        }
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, 
                   didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: String?) {
        print("🔌 WebSocket closed: \(closeCode)")
        
        await MainActor.run {
            self.isConnected = false
            self.deviceActivityManager?.markDeviceAsInactive()
        }
    }
    
    /**
     * Handle sync events from server
     */
    private func handleSyncEvent(_ event: TimerSyncEvent) async {
        switch event.type {
        case .stateChange:
            if let stateDto = event.state {
                await self.updateTimerStateFromDto(stateDto)
            }
            
        case .tick:
            await MainActor.run {
                self.updateTimerDisplay(
                    remaining: event.remainingSeconds ?? self.currentTimerState.remaining,
                    phase: event.phase ?? self.currentTimerState.phase
                )
            }
            
        case .action:
            if let action = event.action {
                await self.applyTimerAction(action)
            }
        }
    }
    
    /**
     * Update timer state from server DTO
     */
    private func updateTimerStateFromDto(_ state: TimerStateDto) async {
        let newLocalState = LocalTimerState(
            remaining: state.remainingSeconds ?? self.currentTimerState.remaining,
            phase: state.phase ?? self.currentTimerState.phase,
            isRunning: state.isRunning ?? self.currentTimerState.isRunning
        )
        
        self.currentTimerState = newLocalState
        
        // Sync via event system
        await apiClient.sendTimerEvent(
            userId: self.userId,
            sourceDeviceId: await self.deviceActivityManager?.getDeviceId() ?? "unknown",
            previousState: mapTimerStateToDto(self.currentTimerState),
            newState: mapTimerStateToDto(newLocalState)
        )
        
        // Update device activity with smart state management
        await self.deviceActivityManager?.updateDeviceState(
            from: mapTimerStateToDto(self.currentTimerState),
            to: newLocalState
        )
        
        // Update UI
        await MainActor.run {
            self.currentTimerState = newLocalState
            self.updateTimerDisplay(
                remaining: newLocalState.remaining,
                phase: newLocalState.phase,
                isRunning: newLocalState.isRunning
            )
        }
    }
    
    /**
     * Apply timer action locally
     */
    private func applyTimerAction(_ action: String) async {
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
        self.currentTimerState.remaining = remaining
        self.currentTimerState.phase = phase
        self.currentTimerState.isRunning = isRunning
        
        // Notify UI of state changes
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
}

/**
 * Timer sync event for WebSocket communication
 */
struct TimerSyncEvent: Codable {
    let type: String
    let action: String?
    let timestamp: Date
    let state: TimerStateDto?
    let remainingSeconds: Int?
    let phase: String
    let deviceId: String
    
    enum EventType: String, Codable {
        case stateChange = "STATE_CHANGE"
        case tick = "TICK"
        case action = "ACTION"
    }
}
