import Foundation
import os

@MainActor
final class WebSocketClient {
    enum State { case connected, connecting, disconnected, reconnecting }

    private let baseURL: URL
    private var webSocketTask: URLSessionWebSocketTask?
    private var state: State = .disconnected
    private var reconnectTimer: Timer?
    private var reconnectInterval: TimeInterval = 1.0

    var currentState: State { state }

    init(baseURL: URL) {
        self.baseURL = baseURL
    }

    func connect(token: String) async {
        disconnect()
        state = .connecting
        print("🔌 WebSocket: connecting to \(baseURL)")

        guard var urlComponent = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            print("❌ WebSocket: invalid URL")
            state = .disconnected
            return
        }
        urlComponent.queryItems = [URLQueryItem(name: "token", value: token)]

        guard let url = urlComponent.url else {
            print("❌ WebSocket: failed to build URL with token")
            state = .disconnected
            return
        }

        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 10
        configuration.timeoutIntervalForResource = 0

        let session = URLSession(configuration: configuration, delegate: nil, delegateQueue: nil)
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        print("🔌 WebSocket: connection initiated")

        await listenForMessages()
    }

    func send(json: [String: Any]) async throws {
        guard state == .connected, let task = webSocketTask else {
            throw WebSocketError.notConnected
        }

        let data = try JSONSerialization.data(withJSONObject: json)
        let string = String(data: data, encoding: .utf8) ?? ""
        try await task.send(.string(string))
    }

    func disconnect() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        if let task = webSocketTask {
            task.cancel()
        }
        webSocketTask = nil
        state = .disconnected
    }

    private func listenForMessages() async {
        guard let task = webSocketTask else { return }

        while true {
            do {
                let message = try await task.receive()
                switch message {
                case .string(let text):
                    handleIncoming(text)
                case .data(let data):
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        handleIncomingJSON(json)
                    }
                @unknown default:
                    break
                }
            } catch {
                print("⚠️ WebSocket: receive error: \(error)")
                state = .disconnected
                break
            }
        }
    }

    private func handleIncoming(_ text: String) {
        let json: [String: Any]
        if let data = text.data(using: .utf8),
           let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            json = parsed
        } else {
            return
        }
        handleIncomingJSON(json)
    }

    private func handleIncomingJSON(_ json: [String: Any]) {
        guard let type = json["type"] as? String else { return }

        switch type {
        case "state":
            if let callback = onTimerState { callback(json) }
        case "pong":
            break
        default:
            break
        }
    }

    var onTimerState: (([String: Any]) -> Void)?

    func sendAction(
        action: String,
        phase: String,
        isRunning: Bool,
        remainingSeconds: Int,
        workDuration: Int,
        breakDuration: Int,
        longBreakDuration: Int,
        autoStartNextSession: Bool,
        shortBreaksCompleted: Int,
        deviceId: String,
        timestamp: Double
    ) async throws {
        try await send(json: [
            "type": "action",
            "action": action,
            "phase": phase,
            "isRunning": isRunning,
            "remainingSeconds": remainingSeconds,
            "workDuration": workDuration,
            "breakDuration": breakDuration,
            "longBreakDuration": longBreakDuration,
            "autoStartNextSession": autoStartNextSession,
            "shortBreaksCompleted": shortBreaksCompleted,
            "deviceId": deviceId,
            "timestamp": timestamp
        ])
    }

    private func scheduleReconnect() {
        guard state != .connected else { return }
        state = .reconnecting
        reconnectTimer?.invalidate()
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: reconnectInterval, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.reconnectInterval = min(self.reconnectInterval * 2, 30)
            Task { @MainActor in
                if let token = AuthManager.shared.getValidAccessToken() {
                    await self.connect(token: token)
                }
            }
        }
    }

    private enum WebSocketError: Error {
        case notConnected
    }
}
