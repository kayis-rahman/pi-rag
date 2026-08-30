import Foundation

struct ProductiveWindowSection: Decodable {
    let startHour: Int
    let endHour: Int
    let totalSessions: Int
    let timezone: String
    let timeRange: String
    let windowHours: Int

    enum CodingKeys: String, CodingKey {
        case startHour = "start_hour"
        case endHour = "end_hour"
        case totalSessions = "total_sessions"
        case timezone
        case timeRange = "time_range"
        case windowHours = "window_hours"
    }
}
