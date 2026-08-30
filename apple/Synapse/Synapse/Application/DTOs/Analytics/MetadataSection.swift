import Foundation

struct MetadataSection: Decodable {
    let requestedAt: Int
    let timeRange: String
    let breakdownType: String
    let timezone: String

    enum CodingKeys: String, CodingKey {
        case requestedAt = "requested_at"
        case timeRange = "time_range"
        case breakdownType = "breakdown_type"
        case timezone
    }
}
