import Foundation

struct RecentSessionData: Decodable, Identifiable {
    var id: String { timestamp }
    let type: String
    let durationMinutes: Int
    let timestamp: String

    enum CodingKeys: String, CodingKey {
        case type
        case durationMinutes = "duration_minutes"
        case timestamp
    }
}
