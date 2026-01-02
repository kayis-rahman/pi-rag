import Foundation

struct TimerActionDto: Codable {
    let action: String
    let phase: String
    let isRunning: Bool
    let workDuration: Int
    let breakDuration: Int
    let longBreakDuration: Int
    let autoStartNextSession: Bool
    let shortBreaksCompleted: Int
    let deviceId: String
    let timestamp: Double

    init(
        action: String,
        phase: String,
        isRunning: Bool,
        workDuration: Int,
        breakDuration: Int,
        longBreakDuration: Int,
        autoStartNextSession: Bool,
        shortBreaksCompleted: Int,
        deviceId: String,
        timestamp: Double
    ) {
        self.action = action
        self.phase = phase
        self.isRunning = isRunning
        self.workDuration = workDuration
        self.breakDuration = breakDuration
        self.longBreakDuration = longBreakDuration
        self.autoStartNextSession = autoStartNextSession
        self.shortBreaksCompleted = shortBreaksCompleted
        self.deviceId = deviceId
        self.timestamp = timestamp
    }
}
