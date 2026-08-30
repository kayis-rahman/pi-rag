import Foundation

struct AnalyticsDashboardResponse: Decodable {
    let dailyTotals: DailyTotalsSection
    let streak: StreakSection
    let productiveWindow: ProductiveWindowSection
    let breakdown: BreakdownSection
    let metadata: MetadataSection

    enum CodingKeys: String, CodingKey {
        case dailyTotals = "daily_totals"
        case streak
        case productiveWindow = "productive_window"
        case breakdown
        case metadata
    }
}
