import Foundation

struct DailyTotal: Identifiable, Equatable {
    let date: Date
    let totalMinutes: Int
    var id: Date { date }
}

struct TopWindow: Equatable {
    let startHour: Int // 0...23
    let endHour: Int   // 0...24 (exclusive)
    let sessionCount: Int
}

@MainActor
class AnalyticsManager: ObservableObject {
    @Published var dashboardData: AnalyticsDashboardResponse?
    @Published var isLoading = false
    @Published var error: Error?

    private let apiClient: AnalyticsApiClient
    private let authManager: AuthManager

    init(apiClient: AnalyticsApiClient, authManager: AuthManager) {
        self.apiClient = apiClient
        self.authManager = authManager
    }

    func fetchDashboard(timeRange: String = "week", breakdown: String = "weekday") async {
        guard authManager.isSignedIn,
              let baseURL = Configuration.fromInfoPlist()?.baseURL else {
            // Not signed in or no API config, use local data
            return
        }

        isLoading = true
        error = nil

        do {
            let jwt = try KeychainStore.loadString(.accessToken) ?? ""
            let response = try await apiClient.fetchDashboard(jwt: jwt, timeRange: timeRange, breakdown: breakdown)
            dashboardData = response
        } catch {
            self.error = error
            print("Failed to fetch analytics dashboard: \(error)")
        }

        isLoading = false
    }

    // MARK: - Computed Properties for UI

    var weeklyChartData: [DailyStats] {
        if let apiData = dashboardData?.dailyTotals.data {
            // Convert API data to chart format
            return apiData.map { entry in
                let date = ISO8601DateFormatter().date(from: entry.date) ?? Date()
                let isToday = Calendar.current.isDateInToday(date)
                return DailyStats(
                    date: date,
                    dayLabel: isToday ? "Today" : formatDay(date),
                    minutes: entry.totalMinutes
                )
            }
        } else {
            // Fall back to local data
            return []
        }
    }

    var todayTotal: Int {
        dashboardData?.dailyTotals.data.last?.totalMinutes ?? 0
    }

    var weeklyTotal: Int {
        dashboardData?.dailyTotals.data.reduce(0) { $0 + $1.totalMinutes } ?? 0
    }

    var bestStreak: Int {
        dashboardData?.streak.current ?? 0
    }

    var recentSessions: [SessionRecord] {
        // This would need to be fetched separately or from local data
        // For now, return empty array as this data isn't in the dashboard response
        []
    }

    private func formatDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

enum AnalyticsService {
    static func last7DaysTotals(records: [SessionRecord], calendar: Calendar = .current) -> [DailyTotal] {
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        let days = (0..<7).reversed().compactMap { offset -> Date? in
            calendar.date(byAdding: .day, value: -offset, to: startOfToday)
        }

        var totals: [Date: Int] = [:]
        for rec in records where rec.isProductive {
            let day = calendar.startOfDay(for: rec.startedAt)
            totals[day, default: 0] += Int(rec.duration / 60.0)
        }

        return days.map { day in
            DailyTotal(date: day, totalMinutes: totals[day, default: 0])
        }
    }

    static func productiveStreak(records: [SessionRecord], calendar: Calendar = .current) -> Int {
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        let productiveDays: Set<Date> = Set(
            records.filter { $0.isProductive }.map { calendar.startOfDay(for: $0.startedAt) }
        )

        var anchor = startOfToday
        if !productiveDays.contains(anchor) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: anchor),
                  productiveDays.contains(yesterday) else {
                return 0
            }
            anchor = yesterday
        }

        var streak = 0
        var day = anchor
        while productiveDays.contains(day) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return streak
    }

    static func topProductiveWindow(records: [SessionRecord], windowHours: Int = 2, calendar: Calendar = .current) -> TopWindow? {
        guard windowHours > 0 else { return nil }
        let productive = records.filter { $0.isProductive }
        guard !productive.isEmpty else { return nil }

        var counts = Array(repeating: 0, count: 24)
        for rec in productive {
            let hour = calendar.component(.hour, from: rec.startedAt)
            counts[hour] += 1
        }

        var bestStart = 0
        var bestCount = -1
        let extended = counts + counts.prefix(windowHours - 1)
        var windowSum = extended.prefix(windowHours).reduce(0, +)

        bestCount = windowSum
        bestStart = 0

        for start in 1..<24 {
            windowSum -= extended[start - 1]
            windowSum += extended[start + windowHours - 1]
            if windowSum > bestCount {
                bestCount = windowSum
                bestStart = start
            }
        }

        let end = (bestStart + windowHours) % 24
        return TopWindow(startHour: bestStart, endHour: end == 0 ? 24 : end, sessionCount: bestCount)
    }
}
