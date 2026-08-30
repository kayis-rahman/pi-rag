import Foundation

struct WeeklyChartData: Decodable {
    let data: [WeeklyEntry]
    let period: Int
    let timezone: String
    let unit: String
}
