import Foundation

/**
 * DTO for timer state synchronization
 * Matches backend TimerStateDto
 */
struct TimerStateDto: Codable {
    let phase: String?
    let remainingSeconds: Int?
    let isRunning: Bool?
    let workDuration: Int?
    let breakDuration: Int?
    let longBreakDuration: Int?
    let autoStartNextSession: Bool?
    let shortBreaksCompleted: Int?
    let totalDuration: Int?
    let lastModifiedTimestamp: Date?
    let deviceId: String?

    enum CodingKeys: String, CodingKey {
        case phase, remainingSeconds, isRunning
        case workDuration, breakDuration, longBreakDuration
        case autoStartNextSession, shortBreaksCompleted
        case totalDuration, lastModifiedTimestamp, deviceId
    }

    init(phase: String? = nil, remainingSeconds: Int? = nil, isRunning: Bool? = nil,
         workDuration: Int? = nil, breakDuration: Int? = nil, longBreakDuration: Int? = nil,
         autoStartNextSession: Bool? = nil, shortBreaksCompleted: Int? = nil,
         totalDuration: Int? = nil, lastModifiedTimestamp: Date? = nil, deviceId: String? = nil) {
        self.phase = phase
        self.remainingSeconds = remainingSeconds
        self.isRunning = isRunning
        self.workDuration = workDuration
        self.breakDuration = breakDuration
        self.longBreakDuration = longBreakDuration
        self.autoStartNextSession = autoStartNextSession
        self.shortBreaksCompleted = shortBreaksCompleted
        self.totalDuration = totalDuration
        self.lastModifiedTimestamp = lastModifiedTimestamp
        self.deviceId = deviceId
    }
}