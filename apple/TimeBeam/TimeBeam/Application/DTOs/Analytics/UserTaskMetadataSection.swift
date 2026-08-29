import Foundation

struct UserTaskMetadataSection: Decodable {
    let requestedAt: Int
    let timeRange: String
    let timezone: String

    enum CodingKeys: String, CodingKey {
        case requestedAt = "requested_at"
        case timeRange = "time_range"
        case timezone
    }
}
