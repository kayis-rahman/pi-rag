import Foundation

struct BreakdownSection: Decodable {
    let data: [BreakdownEntry]
    let breakdownType: String
    let timeRange: String
    let timezone: String

    enum CodingKeys: String, CodingKey {
        case data
        case breakdownType = "breakdown_type"
        case timeRange = "time_range"
        case timezone
    }
}
