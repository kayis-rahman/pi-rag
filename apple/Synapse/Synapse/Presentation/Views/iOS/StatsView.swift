import Charts

import SwiftUI

struct StatsView: View {
    @Environment(SessionLogger.self) var logger
    @Environment(AnalyticsManager.self) var analyticsManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    Text("Your Progress")
                        .font(.system(size: 28, weight: .bold, design: .default))
                        .foregroundColor(Color(red: 27/255, green: 67/255, blue: 50/255))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Weekly Chart
                    StatsCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("This Week")
                                .font(.system(size: 20, weight: .semibold, design: .default))
                                .foregroundColor(Color(red: 27/255, green: 67/255, blue: 50/255))

                            WeeklyBarChart(data: weeklyData())
                                .frame(height: 200)
                        }
                    }

                    // Summary Cards
                    HStack(spacing: 12) {
                        SummaryCard(
                            title: "Today",
                            value: formatDuration(todayTotal()),
                            icon: "sun.max.fill",
                            color: Color(red: 168/255, green: 230/255, blue: 207/255)
                        )

                        SummaryCard(
                            title: "This Week",
                            value: formatDuration(weeklyTotal()),
                            icon: "calendar",
                            color: Color(red: 86/255, green: 197/255, blue: 150/255)
                        )
                    }

                    HStack(spacing: 12) {
                        SummaryCard(
                            title: "Best Streak",
                            value: "\(bestStreak()) days",
                            icon: "flame.fill",
                            color: Color(red: 255/255, green: 159/255, blue: 28/255)
                        )

                        SummaryCard(
                            title: "Focus",
                            value: "25m",
                            icon: "timer",
                            color: Color(red: 168/255, green: 230/255, blue: 207/255)
                        )

                        SummaryCard(
                            title: "Break",
                            value: "5m",
                            icon: "cup.and.saucer.fill",
                            color: Color(red: 255/255, green: 159/255, blue: 28/255)
                        )
                    }

                    // Recent Sessions
                    StatsCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Recent Sessions")
                                .font(.system(size: 20, weight: .semibold, design: .default))
                                .foregroundColor(Color(red: 27/255, green: 67/255, blue: 50/255))

                            VStack(spacing: 8) {
                                ForEach(recentSessions()) { session in
                                    SessionRow(session: session)
                                }

                                if recentSessions().count > 5 {
                                    Text("+\(recentSessions().count - 5) more sessions")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color.secondary.opacity(0.6))
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .padding(.vertical, 8)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .background(Color(red: 247/255, green: 253/255, blue: 251/255).ignoresSafeArea())
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .task {
                await analyticsManager.fetchDashboard()
            }
        }
    }

    // MARK: - Data Helpers

    private func weeklyData() -> [DailyStats] {
        if !analyticsManager.weeklyChartData.isEmpty {
            return analyticsManager.weeklyChartData
        }

        // Fallback to local data
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let days = (0..<7).reversed().map { -1 * $0 }

        return days.map { dayOffset in
            let date = calendar.date(byAdding: .day, value: dayOffset, to: today)!
            let dailySessions = sessionsForDate(date, calendar: calendar)
            let totalMinutes = productiveMinutes(sessions: dailySessions)

            return DailyStats(
                date: date,
                dayLabel: dayOffset == 0 ? "Today" : formatDay(date),
                minutes: totalMinutes
            )
        }
    }

    private func sessionsForDate(_ date: Date, calendar: Calendar) -> [SessionRecordDto] {
        logger.records.filter { record in
            calendar.isDate(record.startedAt, inSameDayAs: date)
        }
    }

    private func productiveMinutes(sessions: [SessionRecordDto]) -> Int {
        sessions
            .filter { $0.isProductive }
            .reduce(0) { $0 + Int($1.durationSeconds / 60) }
    }

    private func todayTotal() -> Int {
        if analyticsManager.dashboardData != nil {
            return analyticsManager.todayTotal
        }

        // Fallback to local data
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let todaySessions = sessionsForDate(today, calendar: calendar)
        return productiveMinutes(sessions: todaySessions)
    }

    private func weeklyTotal() -> Int {
        if analyticsManager.dashboardData != nil {
            return analyticsManager.weeklyTotal
        }

        // Fallback to local data
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let weekStart = calendar.date(byAdding: .day, value: -6, to: today) else {
            return 0
        }

        let weekSessions = logger.records.filter { $0.startedAt >= weekStart }
        return productiveMinutes(sessions: weekSessions)
    }

    private func bestStreak() -> Int {
        if analyticsManager.dashboardData != nil {
            return analyticsManager.bestStreak
        }

        // Fallback to local data - simplified streak calculation
        let productiveRecords = logger.records.filter { $0.isProductive }
        let sortedRecords = productiveRecords.sorted { $0.startedAt > $1.startedAt }

        var currentStreak = 0
        var maxStreak = 0
        var lastDate: Date?
        let calendar = Calendar.current

        for record in sortedRecords {
            let recordDate = calendar.startOfDay(for: record.startedAt)

            if let last = lastDate {
                let daysDiff = calendar.dateComponents([.day], from: last, to: recordDate).day ?? 0

                if daysDiff == 1 {
                    currentStreak += 1
                } else if daysDiff == 0 {
                    // Same day, continue
                    continue
                } else {
                    maxStreak = max(maxStreak, currentStreak)
                    currentStreak = 1
                }
            } else {
                currentStreak = 1
            }

            lastDate = recordDate
        }

        return max(maxStreak, currentStreak)
    }

    private func recentSessions() -> [SessionRecordDto] {
        return logger.records
            .sorted { $0.startedAt > $1.startedAt }
            .prefix(10)
            .map { $0 }
    }

    private func formatDuration(_ minutes: Int) -> String {
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return "\(hours)h \(mins)m"
        } else {
            return "\(minutes)m"
        }
    }

    private func formatDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views

struct StatsCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            content
        }
        .padding(20)
        .glassEffectCardConditional(cornerRadius: 16)
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)

                Spacer()

                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(color)
            }

            Text(title)
                .font(.system(size: 14))
                .foregroundColor(Color.secondary.opacity(0.6))
        }
        .padding(16)
        .glassEffectCardConditional(cornerRadius: 12, tint: color.opacity(0.3))
    }
}

struct WeeklyBarChart: View {
    let data: [DailyStats]

    var body: some View {
        Chart(data) { item in
            BarMark(
                x: .value("Day", item.dayLabel),
                y: .value("Minutes", item.minutes)
            )
            .foregroundStyle(Color(red: 168/255, green: 230/255, blue: 207/255).gradient)
            .cornerRadius(4)
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine().foregroundStyle(Color.secondary.opacity(0.2))
                AxisTick().foregroundStyle(Color.secondary.opacity(0.3))
                AxisValueLabel().foregroundStyle(Color.secondary.opacity(0.6))
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisGridLine().foregroundStyle(Color.secondary.opacity(0.2))
                AxisTick().foregroundStyle(Color.secondary.opacity(0.3))
                AxisValueLabel().foregroundStyle(Color.secondary.opacity(0.6))
            }
        }
    }
}

struct SessionRow: View {
    let session: SessionRecordDto

    var body: some View {
        HStack(spacing: 12) {
            // Phase indicator
            Circle()
                .fill(phaseColor)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(sessionKind.displayName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(red: 27/255, green: 67/255, blue: 50/255))

                Text(formatDuration(Int(session.durationSeconds / 60)))
                    .font(.system(size: 12))
                    .foregroundColor(Color.secondary.opacity(0.6))
            }

            Spacer()

            Text(formatTime(session.startedAt))
                .font(.system(size: 12))
                .foregroundColor(Color.secondary.opacity(0.6))
        }
        .padding(.vertical, 8)
    }

    private var sessionKind: SessionRecord.Kind {
        switch session.kind.uppercased() {
        case "WORK": return .work
        case "SHORTBREAK": return .shortBreak
        case "LONGBREAK": return .longBreak
        default: return .work
        }
    }

    private var phaseColor: Color {
        switch sessionKind {
        case .work: return Color(red: 168/255, green: 230/255, blue: 207/255)
        case .shortBreak: return Color(red: 255/255, green: 159/255, blue: 28/255)
        case .longBreak: return Color(red: 255/255, green: 128/255, blue: 0/255)
        }
    }

    private func formatDuration(_ minutes: Int) -> String {
        return "\(minutes)m"
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Data Models

struct DailyStats: Identifiable {
    let id = UUID()
    let date: Date
    let dayLabel: String
    let minutes: Int
}

#Preview {
    StatsView()
        .environment(SessionLogger())
        .environment(AnalyticsManager(
            apiClient: AnalyticsApiClient(baseURL: URL(string: "https://api.example.com")!),
            authManager: AuthManager()
        ))
}
