import SwiftUI
import Charts

struct StatsView: View {
    @EnvironmentObject var logger: SessionLogger
    @EnvironmentObject var analyticsManager: AnalyticsManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    Text("Your Progress")
                        .font(.system(size: 28, weight: .bold, design: .default))
                        .foregroundColor(Color.themeTextPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Weekly Chart
                    StatsCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("This Week")
                                .font(.system(size: 20, weight: .semibold, design: .default))
                                .foregroundColor(Color.themeTextPrimary)

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
                            color: Color.themePrimary
                        )

                        SummaryCard(
                            title: "This Week",
                            value: formatDuration(weeklyTotal()),
                            icon: "calendar",
                            color: Color.themeAccent
                        )
                    }

                    HStack(spacing: 12) {
                        SummaryCard(
                            title: "Best Streak",
                            value: "\(bestStreak()) days",
                            icon: "flame.fill",
                            color: Color.themeOrangeAccent
                        )

                        SummaryCard(
                            title: "Focus",
                            value: "25m",
                            icon: "timer",
                            color: Color.themePrimary
                        )

                        SummaryCard(
                            title: "Break",
                            value: "5m",
                            icon: "cup.and.saucer.fill",
                            color: Color.themeOrangeAccent
                        )
                    }

                    // Recent Sessions
                    StatsCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Recent Sessions")
                                .font(.system(size: 20, weight: .semibold, design: .default))
                                .foregroundColor(Color.themeTextPrimary)

                            VStack(spacing: 8) {
                                ForEach(recentSessions().prefix(5)) { session in
                                    SessionRow(session: session)
                                }

                                if recentSessions().count > 5 {
                                    Text("+\(recentSessions().count - 5) more sessions")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color.themeTextSecondary)
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
            .background(Color.themeBackground.ignoresSafeArea())
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

        // Get last 7 days
        return (0..<7).reversed().map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            let sessions = logger.records.filter { record in
                calendar.isDate(record.startedAt, inSameDayAs: date)
            }

            let totalMinutes = sessions
                .filter { $0.isProductive }
                .reduce(0) { $0 + Int($1.duration / 60) }

            return DailyStats(
                date: date,
                dayLabel: dayOffset == 0 ? "Today" : formatDay(date),
                minutes: totalMinutes
            )
        }
    }

    private func todayTotal() -> Int {
        if analyticsManager.dashboardData != nil {
            return analyticsManager.todayTotal
        }

        // Fallback to local data
        let today = Calendar.current.startOfDay(for: Date())
        return logger.records
            .filter { Calendar.current.isDate($0.startedAt, inSameDayAs: today) }
            .filter { $0.isProductive }
            .reduce(0) { $0 + Int($1.duration / 60) }
    }

    private func weeklyTotal() -> Int {
        if analyticsManager.dashboardData != nil {
            return analyticsManager.weeklyTotal
        }

        // Fallback to local data
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekStart = calendar.date(byAdding: .day, value: -6, to: today)!

        return logger.records
            .filter { $0.startedAt >= weekStart }
            .filter { $0.isProductive }
            .reduce(0) { $0 + Int($1.duration / 60) }
    }

    private func bestStreak() -> Int {
        if analyticsManager.dashboardData != nil {
            return analyticsManager.bestStreak
        }

        // Fallback to local data - simplified streak calculation
        let sortedRecords = logger.records
            .filter { $0.isProductive }
            .sorted { $0.startedAt > $1.startedAt }

        var currentStreak = 0
        var maxStreak = 0
        var lastDate: Date?

        for record in sortedRecords {
            let recordDate = Calendar.current.startOfDay(for: record.startedAt)

            if let last = lastDate {
                let daysDiff = Calendar.current.dateComponents([.day], from: last, to: recordDate).day ?? 0

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

    private func recentSessions() -> [SessionRecord] {
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
        .background(Color.themeCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
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
                .foregroundColor(Color.themeTextSecondary)
        }
        .padding(16)
        .background(Color.themeCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
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
            .foregroundStyle(Color.themePrimary.gradient)
            .cornerRadius(4)
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine().foregroundStyle(Color.themeTextSecondary.opacity(0.2))
                AxisTick().foregroundStyle(Color.themeTextSecondary.opacity(0.3))
                AxisValueLabel().foregroundStyle(Color.themeTextSecondary)
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisGridLine().foregroundStyle(Color.themeTextSecondary.opacity(0.2))
                AxisTick().foregroundStyle(Color.themeTextSecondary.opacity(0.3))
                AxisValueLabel().foregroundStyle(Color.themeTextSecondary)
            }
        }
    }
}

struct SessionRow: View {
    let session: SessionRecord

    var body: some View {
        HStack(spacing: 12) {
            // Phase indicator
            Circle()
                .fill(phaseColor)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(session.kind.displayName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.themeTextPrimary)

                Text(formatDuration(Int(session.duration / 60)))
                    .font(.system(size: 12))
                    .foregroundColor(Color.themeTextSecondary)
            }

            Spacer()

            Text(formatTime(session.startedAt))
                .font(.system(size: 12))
                .foregroundColor(Color.themeTextSecondary)
        }
        .padding(.vertical, 8)
    }

    private var phaseColor: Color {
        switch session.kind {
        case .work: return Color.themePrimary
        case .shortBreak: return Color.themeOrangeAccent
        case .longBreak: return Color.themeOrangeDeep
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
        .environmentObject(SessionLogger())
        .environmentObject(AnalyticsManager(
            apiClient: AnalyticsApiClient(baseURL: URL(string: "https://api.example.com")!),
            authManager: AuthManager()
        ))
}
