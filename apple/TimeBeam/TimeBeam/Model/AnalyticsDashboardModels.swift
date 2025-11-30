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
