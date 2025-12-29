import Foundation

// MARK: - Timer Action Enum
enum TimerAction: String, Codable {
    case start = "start"
    case pause = "pause"
    case reset = "reset"
    case stop = "stop"
    case advance = "advance"
}

// TimerSyncManager implementation would go here...