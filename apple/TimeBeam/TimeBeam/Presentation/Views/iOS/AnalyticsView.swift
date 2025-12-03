import Charts
import SwiftUI

#if canImport(Charts)
#endif

struct AnalyticsView: View {
    @Environment(\.dismiss) private var dismiss

    // API state
    @State private var weeklyData: WeeklyAnalyticsResponse?
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

    private func loadWeeklyData() {
        print("🔄 AnalyticsView: Starting loadWeeklyData")
        isLoading = true
        errorMessage = nil

        Task {
            do {
                guard let baseURL = URL(string: "http://localhost:8080") else {
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
                        self.errorMessage = "Cannot connect to server. Please ensure the backend is running on localhost:8080"
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

private struct Card<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding(16)
        .background(backgroundStyle)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.themeTextSecondary.opacity(0.16), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var backgroundStyle: some View {
        let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
        #if os(watchOS)
        if #available(watchOS 10.0, *) {
            shape.fill(.regularMaterial)
        } else {
            shape.fill(Color.themeBackground.opacity(0.6))
        }
        #else
        shape.fill(.regularMaterial)
        #endif
    }
}

private struct LegendDot: View {
    let color: Color
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 10, height: 10)
    }
}

private struct ActivityRing: View {
    let progress: Double
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.themeTextSecondary.opacity(0.2), lineWidth: size * 0.12)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Color.themePrimary,
                    style: StrokeStyle(lineWidth: size * 0.12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Weekly Bar Chart

struct WeeklyBarChartView: View {
    let entries: [WeeklyEntry]
    let formatTime: (Int) -> String

    var body: some View {
        #if canImport(Charts)
        if #available(iOS 16, macOS 13, watchOS 9, *) {
            ChartsWeeklyBars(entries: entries, formatTime: formatTime)
        } else {
            FallbackWeeklyBars(entries: entries, formatTime: formatTime)
        }
        #else
        FallbackWeeklyBars(entries: entries, formatTime: formatTime)
        #endif
    }
}

#if canImport(Charts)
@available(iOS 16, macOS 13, watchOS 9, *)
private struct ChartsWeeklyBars: View {
    let entries: [WeeklyEntry]
    let formatTime: (Int) -> String

    var body: some View {
        Chart(entries) { entry in
            BarMark(
                x: .value("Day", entry.weekday),
                y: .value("Minutes", entry.totalMinutes)
            )
            .foregroundStyle(entry.isToday ? Color.themeAccent : Color.themePrimary)
            .cornerRadius(4)
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine().foregroundStyle(Color.themeTextSecondary.opacity(0.1))
                AxisTick().foregroundStyle(Color.themeTextSecondary.opacity(0.3))
                AxisValueLabel {
                    if let minutes = value.as(Int.self) {
                        Text(formatTime(minutes))
                    }
                }
                .foregroundStyle(Color.themeTextSecondary)
            }
        }
    }
}
#endif

private struct FallbackWeeklyBars: View {
    let entries: [WeeklyEntry]
    let formatTime: (Int) -> String

    var body: some View {
        GeometryReader { geo in
            let maxVal = max(entries.map(\.totalMinutes).max() ?? 1, 1)
            let count = max(entries.count, 1)
            let slotWidth = geo.size.width / CGFloat(count)
            let barWidth = max(12, slotWidth * 0.7)

            HStack(alignment: .bottom, spacing: max(4, slotWidth * 0.3)) {
                ForEach(entries) { entry in
                    let h = CGFloat(entry.totalMinutes) / CGFloat(maxVal) * max(geo.size.height - 40, 1)
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(entry.isToday ? Color.themeAccent : Color.themePrimary)
                            .frame(width: barWidth, height: max(h, 2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(entry.isToday ? Color.themeAccent.opacity(0.5) : Color.clear, lineWidth: 2)
                            )

                        Text(entry.weekday)
                            .font(.caption2)
                            .foregroundStyle(Color.themeTextSecondary)
                            .frame(width: barWidth + 4)
                    }
                }
            }
        }
    }
}

// MARK: - Skeleton Loading View

struct ShimmerLoadingView: View {
    @State private var isAnimating = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header card skeleton
                ShimmerCard {
                    HStack(spacing: 16) {
                        // Activity ring placeholder
                        Circle()
                            .fill(Color.themeTextSecondary.opacity(0.1))
                            .frame(width: 60, height: 60)

                        VStack(alignment: .leading, spacing: 6) {
                            // Title placeholder
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.themeTextSecondary.opacity(0.1))
                                .frame(width: 120, height: 16)

                            // Subtitle placeholder
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.themeTextSecondary.opacity(0.1))
                                .frame(width: 140, height: 12)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            // Time placeholder
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.themeTextSecondary.opacity(0.1))
                                .frame(width: 80, height: 18)

                            // Label placeholder
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.themeTextSecondary.opacity(0.1))
                                .frame(width: 60, height: 10)
                        }
                    }
                }

                // Chart card skeleton
                ShimmerCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            // Chart title placeholder
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.themeTextSecondary.opacity(0.1))
                                .frame(width: 100, height: 16)

                            Spacer()

                            // Legend dot
                            Circle()
                                .fill(Color.themeTextSecondary.opacity(0.1))
                                .frame(width: 10, height: 10)

                            // Legend text placeholder
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.themeTextSecondary.opacity(0.1))
                                .frame(width: 80, height: 12)
                        }

                        // Chart area placeholder
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.themeTextSecondary.opacity(0.05))
                                .frame(height: 220)

                            // Bar chart placeholders
                            HStack(alignment: .bottom, spacing: 8) {
                                ForEach(0..<7) { _ in
                                    VStack(spacing: 4) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.themeTextSecondary.opacity(0.1))
                                            .frame(width: 20, height: .random(in: 40...180))

                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.themeTextSecondary.opacity(0.1))
                                            .frame(width: 24, height: 10)
                                    }
                                }
                            }
                        }

                        HStack {
                            // Footer text placeholder
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.themeTextSecondary.opacity(0.1))
                                .frame(width: 160, height: 12)

                            Spacer()

                            // Average placeholder
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.themeTextSecondary.opacity(0.1))
                                .frame(width: 70, height: 12)
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color.themeBackground.opacity(0.4))
        .overlay(
            ShimmerEffect(isAnimating: $isAnimating)
        )
        .onAppear {
            withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Shimmer Components

private struct ShimmerCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.themeCardBackground.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.themeTextSecondary.opacity(0.1), lineWidth: 1)
        )
    }
}

private struct ShimmerEffect: View {
    @Binding var isAnimating: Bool

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Shimmer overlay
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                .clear,
                                Color.white.opacity(0.1),
                                .clear
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * 0.8)
                    .offset(x: isAnimating ? geometry.size.width : -geometry.size.width)
                    .blendMode(.overlay)
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - IconBadge

private struct IconBadge: View {
    let systemName: String
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.17))
                .frame(width: 32, height: 32)
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
        }
        .frame(width: 32, height: 32)
    }
}
