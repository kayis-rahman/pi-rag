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

struct DailyTotalsSection: Decodable {
    let data: [DailyTotalEntry]
    let period: Int
    let timezone: String
    let unit: String
}

struct DailyTotalEntry: Decodable, Identifiable {
    var id: String { date }
    let date: String     // "YYYY-MM-DD"
    let totalMinutes: Int
    let sessionCount: Int

    enum CodingKeys: String, CodingKey {
        case date
        case totalMinutes = "total_minutes"
        case sessionCount = "session_count"
    }
}

struct StreakSection: Decodable {
    let current: Int
    let unit: String
}

struct ProductiveWindowSection: Decodable {
    let startHour: Int
    let endHour: Int
    let totalSessions: Int
    let timezone: String
    let timeRange: String
    let windowHours: Int

    enum CodingKeys: String, CodingKey {
        case startHour = "start_hour"
        case endHour = "end_hour"
        case totalSessions = "total_sessions"
        case timezone
        case timeRange = "time_range"
        case windowHours = "window_hours"
    }
}

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

// MARK: - Weekly Analytics Models

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

struct WeeklyChartData: Decodable {
    let data: [WeeklyEntry]
    let period: Int
    let timezone: String
    let unit: String
}

struct WeeklyEntry: Decodable, Identifiable {
    var id: String { date }
    let date: String
    let totalMinutes: Int
    let sessionCount: Int
    let weekday: String
    let isToday: Bool

    enum CodingKeys: String, CodingKey {
        case date
        case totalMinutes = "total_minutes"
        case sessionCount = "session_count"
        case weekday
        case isToday = "is_today"
    }
}

struct TodayFocusData: Decodable {
    let minutes: Int
    let sessions: Int
}

struct WeeklyTotalData: Decodable {
    let minutes: Int
    let sessions: Int
}

struct BestStreakData: Decodable {
    let days: Int
    let unit: String
}

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
