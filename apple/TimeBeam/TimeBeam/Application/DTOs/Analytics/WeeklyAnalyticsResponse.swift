import Foundation

struct WeeklyAnalyticsResponse: Decodable {
    let weeklyChart: WeeklyChartData
    let todayFocus: TodayFocusData
    let weeklyTotal: WeeklyTotalData
    let bestStreak: BestStreakData
    let recentSessions: [RecentSessionData]
    let requestedAt: Int

    enum CodingKeys: String, CodingKey {
        case weeklyChart = "weekly_chart"
        case todayFocus = "today_focus"
        case weeklyTotal = "weekly_total"
        case bestStreak = "best_streak"
        case recentSessions = "recent_sessions"
        case requestedAt = "requested_at"
    }
}
