import Foundation

struct DailyTotalsSection: Decodable {
    let data: [DailyTotalEntry]
    let period: Int
    let timezone: String
    let unit: String
}
