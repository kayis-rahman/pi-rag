import Charts
import SwiftUI

#if canImport(Charts)
#endif

struct AnalyticsView: View {
    @Environment(\.dismiss) private var dismiss

    // API state
    @State private var weeklyData: WeeklyAnalyticsResponse?
    @State private var taskData: UserTaskAnalyticsResponse?
    @State private var isLoading = false
    @State private var errorMessage: String?

    // Convert API data to chart format
    private var weeklyEntries: [WeeklyEntry] {
        weeklyData?.weeklyChart.data ?? []
    }

    private var todayFocus: TodayFocusData? {
        weeklyData?.todayFocus
    }

    private var weeklyTotal: WeeklyTotalData? {
        weeklyData?.weeklyTotal
    }

    private var bestStreak: BestStreakData? {
        weeklyData?.bestStreak
    }

    private var recentSessions: [RecentSessionData] {
        weeklyData?.recentSessions ?? []
    }

    // Time formatting helper - shows days/hours for large values
    private func formatTime(_ minutes: Int) -> String {
        if minutes == 0 { return "0m" }

        let totalHours = minutes / 60
        let remainingMinutes = minutes % 60

        if totalHours >= 24 {
            // Show days and hours format for large values
            let days = totalHours / 24
            let hours = totalHours % 24
            if hours == 0 {
                return "\(days)d"
            } else {
                return "\(days)d \(hours)h"
            }
        } else {
            // Show hours and minutes for smaller values
            if totalHours > 0 {
                return remainingMinutes > 0 ? "\(totalHours)h \(remainingMinutes)m" : "\(totalHours)h"
            } else {
                return "\(remainingMinutes)m"
            }
        }
    }

    var body: some View {
        Group {
            #if os(iOS)
            NavigationStack {
                content
                    .navigationTitle("Analytics")
            }
            .onAppear {
                if weeklyData == nil {
                    loadWeeklyData()
                }
                if taskData == nil {
                    loadTaskData()
                }
            }
            #elseif os(watchOS)
            if #available(watchOS 9.0, *) {
                NavigationStack {
                    content
                        .navigationTitle("Analytics")
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button {
                                    dismiss()
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.body.weight(.semibold))
                                }
                                .accessibilityLabel("Close")
                            }
                        }
                }
                .onAppear {
                    loadWeeklyData()
                }
            } else {
                content
                    .onAppear {
                        loadWeeklyData()
                    }
            }
            #else
            content
                .frame(minWidth: 460, minHeight: 540)
                .toolbar {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                    }
                    .help("Close")
                }
                .onAppear {
                    loadWeeklyData()
                }
            #endif
        }
    }

    // MARK: - Content

    private var content: some View {
        let _ = print("🎨 AnalyticsView: Rendering content - isLoading: \(isLoading), weeklyData: \(weeklyData == nil ? "nil" : "has \(weeklyData!.weeklyChart.data.count) entries"), error: \(errorMessage ?? "none")")

        return ZStack {
            if isLoading {
                ShimmerLoadingView()
            } else if let error = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text("Unable to Load Analytics")
                        .font(.headline)
                    Text(error)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button("Try Again") {
                        loadWeeklyData()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            } else if weeklyData != nil {
                ScrollView {
                    VStack(spacing: 16) {
                        headerCard
                        weeklyChartCard

                        // Summary Cards
                        HStack(spacing: 16) {
                            summaryCard(
                                icon: "clock.fill",
                                title: "Today",
                                value: formatTime(todayFocus?.minutes ?? 0),
                                subtitle: "\(todayFocus?.sessions ?? 0) sessions",
                                color: .blue
                            )
                            summaryCard(
                                icon: "calendar",
                                title: "Weekly Total",
                                value: formatTime(weeklyTotal?.minutes ?? 0),
                                subtitle: "\(weeklyTotal?.sessions ?? 0) sessions",
                                color: .green
                            )
                            summaryCard(
                                icon: "flame.fill",
                                title: "Best Streak",
                                value: "\(bestStreak?.days ?? 0)",
                                subtitle: "days",
                                color: .orange
                            )
                        }
                        .fixedSize(horizontal: false, vertical: true)

                        // Session History
                        sessionHistoryCard

                        // Task Analytics
                        if taskData != nil {
                            taskAnalyticsCard
                        }
                    }
                    .padding()
                }
                .background(Color.blue.opacity(0.1)) // Debug: visible background
            } else {
                // No data state - this should not appear if API succeeded
                VStack(spacing: 16) {
                    Image(systemName: "chart.bar")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("No Data Available")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("weeklyData: \(weeklyData == nil ? "nil" : "has data")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("isLoading: \(isLoading)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Button("Retry Load") {
                        loadWeeklyData()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
    }

    // MARK: - API Loading

    private func loadTaskData() {
        print("🔄 AnalyticsView: Starting loadTaskData")
        _Concurrency.Task {
            do {
                guard let baseURL = URL(string: ProcessInfo.processInfo.environment["API_BASE_URL"] ?? "http://192.168.0.173:8080") else {
                    throw NSError(domain: "AnalyticsView", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid server URL"])
                }

                let jwt = try KeychainStore.loadString(.accessToken) ?? ""
                if jwt.isEmpty {
                    throw NSError(domain: "AnalyticsView", code: 401, userInfo: [NSLocalizedDescriptionKey: "Please sign in to view analytics"])
                }

                let api = AnalyticsApiClient(baseURL: baseURL)
                print("📡 AnalyticsView: Making task analytics API call...")
                let data = try await api.fetchTaskAnalytics(jwt: jwt)
                print("✅ AnalyticsView: UserTask analytics API call successful")

                await MainActor.run {
                    self.taskData = data
                }
            } catch let error as NSError {
                print("❌ AnalyticsView: UserTask analytics API error - domain: \(error.domain), code: \(error.code), message: \(error.localizedDescription)")
                // Don't set error message for task data - it's optional
            } catch {
                print("❌ AnalyticsView: Unexpected task analytics error: \(error)")
            }
        }
    }

    private func loadWeeklyData() {
        print("🔄 AnalyticsView: Starting loadWeeklyData")
        isLoading = true
        errorMessage = nil

        _Concurrency.Task {
            do {
                guard let baseURL = URL(string: ProcessInfo.processInfo.environment["API_BASE_URL"] ?? "http://192.168.0.173:8080") else {
                    throw NSError(domain: "AnalyticsView", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid server URL"])
                }
                print("🌐 AnalyticsView: Using baseURL: \(baseURL)")

                let jwt = try KeychainStore.loadString(.accessToken) ?? ""
                print("🔑 AnalyticsView: JWT token present: \(!jwt.isEmpty)")
                if jwt.isEmpty {
                    throw NSError(domain: "AnalyticsView", code: 401, userInfo: [NSLocalizedDescriptionKey: "Please sign in to view analytics"])
                }

                let api = AnalyticsApiClient(baseURL: baseURL)
                print("📡 AnalyticsView: Making API call...")
                let data = try await api.fetchWeeklyAnalytics(jwt: jwt)
                print("✅ AnalyticsView: API call successful, received \(data.weeklyChart.data.count) entries")

                await MainActor.run {
                    self.weeklyData = data
                    self.isLoading = false
                    print("🎉 AnalyticsView: Data loaded successfully")
                }
            } catch let error as NSError {
                print("❌ AnalyticsView: API error - domain: \(error.domain), code: \(error.code), message: \(error.localizedDescription)")
                await MainActor.run {
                    if error.domain == "AnalyticsAPI" {
                        self.errorMessage = error.localizedDescription
                    } else if error.domain == NSCocoaErrorDomain && error.code == 256 {
                        self.errorMessage = "Cannot connect to server. Please ensure backend is running on \(ProcessInfo.processInfo.environment["API_BASE_URL"] ?? "192.168.0.173:8080")"
                    } else {
                        self.errorMessage = error.localizedDescription
                    }
                    self.isLoading = false
                }
            } catch {
                print("❌ AnalyticsView: Unexpected error: \(error)")
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }

    // MARK: - Cards

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                ActivityRing(progress: deepWorkProgress, size: 60)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Weekly?")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.primary)
                    Text("Your focus journey this week")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(deepWorkProgressText)
                        .font(.title2.weight(.bold))
                        .foregroundColor(.blue)
                    Text("Deep work goal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.9))
        .cornerRadius(14)
        .shadow(radius: 2)
    }

    private var weeklyChartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Daily Focus")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Circle()
                    .fill(Color.blue)
                    .frame(width: 10, height: 10)
                Text("Focus Time")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Debug: Simple colored rectangles instead of chart
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(weeklyEntries) { entry in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(entry.isToday ? Color.red : Color.green)
                            .frame(width: 30, height: max(CGFloat(entry.totalMinutes) / 3, 10))

                        Text(entry.weekday)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(height: 120)

            HStack {
                Text("Minutes focused per day this week")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Spacer()
                Text(weeklyAverageText)
                    .font(.footnote.weight(.medium))
                    .foregroundColor(.blue)
            }
        }
        .padding(16)
        .background(Color.green.opacity(0.1))
        .cornerRadius(14)
        .shadow(radius: 2)
    }

    // MARK: - Computed Properties

    private var weeklyTotalMinutes: Int {
        weeklyEntries.reduce(0) { $0 + $1.totalMinutes }
    }

    private var weeklyProgress: Double {
        let avg = Double(weeklyTotalMinutes) / 7.0
        return min(max(avg / 150.0, 0), 1) // Assuming 150 min/day is a good target
    }

    private var weeklyAverageText: String {
        let avg = Double(weeklyTotalMinutes) / 7.0
        return "Avg \(formatTime(Int(avg.rounded())))"
    }

    // Deep work goal: 4 hours × 5 days = 20 hours per week
    private var deepWorkProgress: Double {
        let deepWorkGoalHours = 20.0 // 4 hours × 5 days
        let actualWeeklyHours = Double(weeklyTotal?.minutes ?? 0) / 60.0
        return min(actualWeeklyHours / deepWorkGoalHours, 1.0)
    }

    private var deepWorkProgressText: String {
        let actualHours = Int((Double(weeklyTotal?.minutes ?? 0) / 60.0).rounded())
        return "\(actualHours)h / 20h"
    }

    // MARK: - Helper Views

    private func summaryCard(icon: String, title: String, value: String, subtitle: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
                Spacer()
            }

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.title3.weight(.bold))
                .foregroundColor(.primary)

            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white.opacity(0.9))
        .cornerRadius(12)
        .shadow(radius: 1)
    }

    private var sessionHistoryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Sessions")
                .font(.headline)
                .foregroundColor(.primary)

            if recentSessions.isEmpty {
                Text("No recent sessions")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(recentSessions.prefix(10)) { session in
                    HStack(spacing: 12) {
                        // Session type icon
                        ZStack {
                            Circle()
                                .fill(session.type == "WORK" ? Color.blue.opacity(0.2) : Color.green.opacity(0.2))
                                .frame(width: 32, height: 32)
                            Image(systemName: session.type == "WORK" ? "brain.head.profile" : "cup.and.saucer")
                                .font(.system(size: 14))
                                .foregroundColor(session.type == "WORK" ? .blue : .green)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(session.type == "WORK" ? "Focus" : "Break")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.primary)

                            Text("\(session.durationMinutes)m")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Text(formatSessionTime(session.timestamp))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.9))
        .cornerRadius(14)
        .shadow(radius: 2)
    }

    private var taskAnalyticsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Task Analytics")
                .font(.headline)
                .foregroundColor(.primary)

            if let metrics = taskData?.taskMetrics {
                HStack(spacing: 16) {
                    summaryCard(
                        icon: "checklist",
                        title: "Total Tasks",
                        value: "\(metrics.totalTasks)",
                        subtitle: "\(metrics.activeTasks) active",
                        color: .purple
                    )
                    summaryCard(
                        icon: "checkmark.circle.fill",
                        title: "Completed",
                        value: "\(metrics.completedTasks)",
                        subtitle: "\(String(format: "%.1f", metrics.completionRate))% rate",
                        color: .green
                    )
                    summaryCard(
                        icon: "clock.fill",
                        title: "Time Spent",
                        value: formatTime(metrics.totalTimeSpent),
                        subtitle: "on tasks",
                        color: .blue
                    )
                }
                .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("Task analytics loading...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            }
        }
        .padding(16)
        .background(Color.purple.opacity(0.1))
        .cornerRadius(14)
        .shadow(radius: 2)
    }

    private func formatSessionTime(_ timestamp: String) -> String {
        // Simple time formatting - just show HH:MM
        if let isoDate = ISO8601DateFormatter().date(from: timestamp) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: isoDate)
        }
        return "Now"
    }
}

// MARK: - Components

