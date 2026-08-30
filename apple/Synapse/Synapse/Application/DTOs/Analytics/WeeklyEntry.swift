import Foundation

struct WeeklyEntry: Decodable, Identifiable {
    var id: String { date }
    let date: String
    let totalMinutes: Int
    let sessionCount: Int
    let weekday: String
    let isToday: Bool

    enum CodingKeys: String, CodingKey {
        case date
        case totalMinutes = "total_minutes"
        case sessionCount = "session_count"
        case weekday
        case isToday = "is_today"
    }
}
