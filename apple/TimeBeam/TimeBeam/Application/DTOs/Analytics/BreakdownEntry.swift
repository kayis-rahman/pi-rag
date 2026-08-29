import Foundation

struct BreakdownEntry: Decodable, Identifiable {
    var id: String { breakdownLabel }
    let breakdownLabel: String
    let workSessionCount: Int
    let dayCount: Int
    let totalMinutes: Int
    let averageMinutesPerDay: Double

    enum CodingKeys: String, CodingKey {
        case breakdownLabel = "breakdown_label"
        case workSessionCount = "work_session_count"
        case dayCount = "day_count"
        case totalMinutes = "total_minutes"
        case averageMinutesPerDay = "average_minutes_per_day"
    }
}
