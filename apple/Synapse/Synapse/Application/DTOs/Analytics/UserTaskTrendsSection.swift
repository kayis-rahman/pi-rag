import Foundation

struct UserTaskTrendsSection: Decodable {
    let data: [UserTaskTrendEntry]
    let period: Int
    let timezone: String
}
