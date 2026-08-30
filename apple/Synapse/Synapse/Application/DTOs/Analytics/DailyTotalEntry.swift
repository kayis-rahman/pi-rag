import Foundation

struct DailyTotalEntry: Decodable, Identifiable {
    var id: String { date }
    let date: String     // "YYYY-MM-DD"
    let totalMinutes: Int
    let sessionCount: Int

    enum CodingKeys: String, CodingKey {
        case date
        case totalMinutes = "total_minutes"
        case sessionCount = "session_count"
    }
}
