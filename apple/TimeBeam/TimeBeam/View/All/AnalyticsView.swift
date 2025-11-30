import SwiftUI
#if canImport(Charts)
import Charts
#endif

// MARK: - Public helpers shared by charts

struct WeekdayTotal: Identifiable, Equatable {
    // 0 = Monday ... 6 = Sunday
    let weekdayIndex: Int
    let label: String
    let totalMinutes: Int
    var id: Int { weekdayIndex }
}

enum AnalyticsScope: String, CaseIterable, Identifiable {
    case week = "Week"
    case month = "Month"
    case all = "All"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .week: return "7.circle"
        case .month: return "calendar"
        case .all: return "infinity"
        }
    }
}

enum AnalyticsGrouping: String, CaseIterable, Identifiable {
    case byDay = "By Day"
    case byWeekday = "By Weekday"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .byDay: return "chart.bar"
        case .byWeekday: return "square.grid.3x3"
        }
    }
}

struct AnalyticsView: View {
    @EnvironmentObject private var logger: SessionLogger
    @Environment(\.dismiss) private var dismiss

    @State private var scope: AnalyticsScope = .week
    @State private var grouping: AnalyticsGrouping = .byDay

    // API state
    @State private var dashboardData: AnalyticsDashboardResponse?
    @State private var isLoading = false
    @State private var errorMessage: String?

    // Convert API data to chart format
    private var dailyTotalsForChart: [DailyTotal] {
        guard let data = dashboardData?.dailyTotals.data else { return [] }
        return data.map { entry in
            // Parse date string to Date
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let date = dateFormatter.date(from: entry.date) ?? Date()
            return DailyTotal(date: date, totalMinutes: entry.totalMinutes)
        }
    }

    private var weekdayTotalsForChart: [WeekdayTotal] {
        // Convert breakdown data to weekday format
        guard let breakdown = dashboardData?.breakdown.data else { return [] }

        // Group by day of week and sum minutes
        var weekdayMinutes: [Int: Int] = [:]
        var weekdayLabels: [Int: String] = [:]

        for entry in breakdown {
            if let dayIndex = dayOfWeekIndex(from: entry.breakdownLabel) {
                weekdayMinutes[dayIndex, default: 0] += entry.totalMinutes
                weekdayLabels[dayIndex] = entry.breakdownLabel
            }
        }

        return (0..<7).map { index in
            WeekdayTotal(
                weekdayIndex: index,
                label: weekdayLabels[index] ?? defaultWeekdayLabel(index),
                totalMinutes: weekdayMinutes[index] ?? 0
            )
        }
    }

    private func dayOfWeekIndex(from dayName: String) -> Int? {
        let days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        return days.firstIndex(where: { dayName.hasPrefix($0) })
    }

    private func defaultWeekdayLabel(_ idxMon0: Int) -> String {
        ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"][idxMon0]
    }

    var body: some View {
        Group {
            #if os(iOS)
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
                loadAnalyticsData()
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
                    loadAnalyticsData()
                }
            } else {
                content
                    .onAppear {
                        loadAnalyticsData()
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
                    loadAnalyticsData()
                }
            #endif
        }
    }

    // MARK: - Content

    private var content: some View {
        ZStack {
            if isLoading {
                ProgressView("Loading Analytics…")
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
                        loadAnalyticsData()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        headerCard
                        chartAndFiltersCard
                        streakCard
                        topWindowCard
                    }
                    .padding()
                }
                .background(Color.themeBackground.opacity(0.4))
            }
        }
    }

    // MARK: - API Loading

    private func loadAnalyticsData() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                guard let baseURL = URL(string: "http://localhost:8080") else {
                    throw NSError(domain: "AnalyticsView", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid server URL"])
                }

                let jwt = try KeychainStore.loadString(.accessToken) ?? ""
                if jwt.isEmpty {
                    throw NSError(domain: "AnalyticsView", code: 401, userInfo: [NSLocalizedDescriptionKey: "Please sign in to view analytics"])
                }

                let api = AnalyticsApiClient(baseURL: baseURL)
                let data = try await api.fetchDashboard(jwt: jwt, timeRange: "all", breakdown: "weekday")

                await MainActor.run {
                    self.dashboardData = data
                    self.isLoading = false
                }
            } catch let error as NSError {
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
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }

    // MARK: - Cards

    private var headerCard: some View {
        Card {
            HStack(spacing: 16) {
                ActivityRing(progress: ringProgress, size: 60)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Analytics & Insights")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.themeTextPrimary)
                        .shadow(color: Color.black.opacity(0.12), radius: 1, x: 0, y: 1)
                    Text(subtitleForScope())
                        .font(.footnote)
                        .foregroundStyle(Color.themeTextSecondary.opacity(0.9))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(totalMinutesForScope())m")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.themePrimary)
                    Text("Total focused")
                        .font(.caption)
                        .foregroundStyle(Color.themeTextSecondary.opacity(0.9))
                }
            }
        }
    }

    // Combined filters + chart in one card
    private var chartAndFiltersCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Segmented(items: AnalyticsScope.allCases, selection: $scope) { s in
                    Label(s.rawValue, systemImage: s.icon)
                }
                Segmented(items: AnalyticsGrouping.allCases, selection: $grouping) { g in
                    Label(g.rawValue, systemImage: g.icon)
                }

                HStack {
                    Text(chartTitle)
                        .font(.headline)
                        .foregroundStyle(Color.themeTextPrimary)
                    Spacer()
                    LegendDot(color: Color.themePrimary)
                    Text("Focused Minutes")
                        .font(.caption)
                        .foregroundStyle(Color.themeTextSecondary.opacity(0.9))
                }

                if grouping == .byDay {
                    DayChartView(totals: totalsForScopeByDay())
                        .frame(height: 220)
                } else {
                    WeekdayChartView(weekdayTotals: totalsForScopeByWeekday())
                        .frame(height: 220)
                }

                HStack {
                    Text(footnoteForScope())
                        .font(.footnote)
                        .foregroundStyle(Color.themeTextSecondary.opacity(0.9))
                    Spacer()
                    Text(avgForScopeText())
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(Color.themeSecondary)
                }
            }
        }
    }

    private var streakCard: some View {
        Card {
            let s = dashboardData?.streak.current ?? 0
            HStack(spacing: 12) {
                IconBadge(systemName: "flame.fill", color: Color.themePrimary)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Streak")
                        .font(.headline)
                        .foregroundStyle(Color.themeTextPrimary)
                    Text(s == 0 ? "No current streak yet" :
                         (s == 1 ? "You focused 1 day in a row" : "You focused \(s) days in a row"))
                        .foregroundStyle(Color.themeTextSecondary.opacity(0.95))
                }
                Spacer()
            }
        }
    }

    private var topWindowCard: some View {
        Card {
            let window = dashboardData?.productiveWindow
            HStack(spacing: 12) {
                IconBadge(systemName: "clock.fill", color: Color.themeSecondary)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Top Time of Day")
                        .font(.headline)
                        .foregroundStyle(Color.themeTextPrimary)
                    if let window = window {
                        Text(windowTextFromAPI(window))
                            .foregroundStyle(Color.themeTextSecondary.opacity(0.95))
                    } else {
                        Text("Not enough data yet")
                            .foregroundStyle(Color.themeTextSecondary.opacity(0.95))
                    }
                }
                Spacer()
            }
        }
    }

    // MARK: - Data prep

    private var chartTitle: String {
        switch scope {
        case .week: return grouping == .byDay ? "Last 7 Days" : "Last 7 Days by Weekday"
        case .month: return grouping == .byDay ? "Last 30 Days" : "Last 30 Days by Weekday"
        case .all: return grouping == .byDay ? "All Time (by Day)" : "All Time (by Weekday)"
        }
    }

    private func footnoteForScope() -> String {
        grouping == .byDay ? "Minutes focused per calendar day" : "Minutes focused by weekday"
    }

    private func subtitleForScope() -> String {
        switch scope {
        case .week: return "Week overview"
        case .month: return "Month overview"
        case .all: return "All-time overview"
        }
    }

    private func filteredRecordsForScope() -> [SessionRecord] {
        let records = logger.records
        let cal = Calendar.current
        let now = Date()

        switch scope {
        case .week:
            guard let start = cal.date(byAdding: .day, value: -6, to: cal.startOfDay(for: now)) else { return records }
            return records.filter { $0.startedAt >= start }
        case .month:
            guard let start = cal.date(byAdding: .day, value: -29, to: cal.startOfDay(for: now)) else { return records }
            return records.filter { $0.startedAt >= start }
        case .all:
            return records
        }
    }

    private func totalsForScopeByDay() -> [DailyTotal] {
        // For now, return all daily totals from API since we fetch "all" time range
        // In a full implementation, we'd need to filter by scope on the client side
        // or modify the API to accept different time ranges
        return dailyTotalsForChart
    }

    private func totalsForScopeByWeekday() -> [WeekdayTotal] {
        return weekdayTotalsForChart
    }

    private func totalMinutesForScope() -> Int {
        // Sum all daily totals from API data
        return dailyTotalsForChart.reduce(0) { $0 + $1.totalMinutes }
    }

    private func avgForScopeText() -> String {
        let totals = totalsForScopeByDay()
        guard !totals.isEmpty else { return "Avg 0m/day" }
        let sum = totals.reduce(0) { $0 + $1.totalMinutes }
        let avg = Double(sum) / Double(totals.count)
        return "Avg \(Int(avg.rounded()))m/day"
    }

    private var ringProgress: Double {
        let totals = totalsForScopeByDay()
        guard !totals.isEmpty else { return 0 }
        let sum = totals.reduce(0) { $0 + $1.totalMinutes }
        let avg = Double(sum) / Double(totals.count)
        return min(max(avg / 150.0, 0), 1)
    }

    private func lastNDaysTotals(records: [SessionRecord], days: Int, calendar: Calendar) -> [DailyTotal] {
        let startOfToday = calendar.startOfDay(for: Date())
        let bucketDays = (0..<days).reversed().map { offset -> Date in
            calendar.date(byAdding: .day, value: -offset, to: startOfToday)!
        }
        var totals: [Date: Int] = [:]
        for rec in records where rec.isProductive {
            let day = calendar.startOfDay(for: rec.startedAt)
            totals[day, default: 0] += Int(rec.duration / 60.0)
        }
        return bucketDays.map { day in
            DailyTotal(date: day, totalMinutes: totals[day, default: 0])
        }
    }

    private func totalsForAllByDay(records: [SessionRecord], calendar: Calendar) -> [DailyTotal] {
        guard let first = records.map({ calendar.startOfDay(for: $0.startedAt) }).min() else {
            return []
        }
        let start = calendar.startOfDay(for: first)
        let startOfToday = calendar.startOfDay(for: Date())
        let days = calendar.dateComponents([.day], from: start, to: startOfToday).day ?? 0
        return lastNDaysTotals(records: records, days: max(days + 1, 1), calendar: calendar)
    }

    private func weekdayTotals(records: [SessionRecord]) -> [WeekdayTotal] {
        let cal = Calendar.current
        var totals = Array(repeating: 0, count: 7)
        var labels = Array(repeating: "", count: 7)

        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.setLocalizedDateFormatFromTemplate("EEE")

        for rec in records where rec.isProductive {
            let wd = cal.component(.weekday, from: rec.startedAt) // 1=Sun...7=Sat
            let idx = (wd + 5) % 7 // 0=Mon...6=Sun
            totals[idx] += Int(rec.duration / 60.0)

            var comps = DateComponents()
            comps.weekday = wd
            let any = cal.date(from: comps) ?? Date()
            labels[idx] = formatter.string(from: any)
        }

        return (0..<7).map { i in
            WeekdayTotal(
                weekdayIndex: i,
                label: labels[i].isEmpty ? defaultWeekdayLabel(i) : labels[i],
                totalMinutes: totals[i]
            )
        }
    }

    private func hourLabel(_ hour24: Int) -> String {
        var comps = DateComponents()
        comps.hour = hour24
        let cal = Calendar.current
        let date = cal.date(from: comps) ?? Date()
        let fmt = DateFormatter()
        fmt.locale = .current
        fmt.dateFormat = "h a"
        return fmt.string(from: date)
    }

    private func windowText(_ window: TopWindow?) -> String {
        guard let w = window else { return "Not enough data yet" }
        let start = hourLabel(w.startHour)
        let end = hourLabel(w.endHour % 24)
        return "Most sessions between \(start) – \(end)"
    }

    private func windowTextFromAPI(_ window: ProductiveWindowSection) -> String {
        let start = hourLabel(window.startHour)
        let end = hourLabel(window.endHour)
        return "Most sessions between \(start) – \(end)"
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

// Cross-platform segmented picker wrapper
private struct Segmented<Item: Hashable & Identifiable, LabelView: View>: View {
    let items: [Item]
    @Binding var selection: Item
    let label: (Item) -> LabelView

    init(items: [Item], selection: Binding<Item>, @ViewBuilder label: @escaping (Item) -> LabelView) {
        self.items = items
        self._selection = selection
        self.label = label
    }

    var body: some View {
        #if os(watchOS)
        Picker(selection: $selection) {
            ForEach(items) { item in
                label(item).tag(item)
            }
        } label: {
            EmptyView()
        }
        .pickerStyle(.inline)
        #else
        Picker(selection: $selection) {
            ForEach(items) { item in
                label(item).tag(item)
            }
        } label: {
            EmptyView()
        }
        .pickerStyle(.segmented)
        .tint(Color.themePrimary)
        #endif
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

// MARK: - Charts

struct DayChartView: View {
    let totals: [DailyTotal]

    init(totals: [DailyTotal]) { self.totals = totals }

    var body: some View {
        #if canImport(Charts)
        if #available(iOS 16, macOS 13, watchOS 9, *) {
            ChartsDayBars(totals: totals)
        } else {
            FallbackBars(totals: totals, label: { shortDate($0) })
        }
        #else
        FallbackBars(totals: totals, label: { shortDate($0) })
        #endif
    }

    private func shortDate(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.locale = .current
        fmt.setLocalizedDateFormatFromTemplate("Md")
        return fmt.string(from: date)
    }

    private struct FallbackBars: View {
        let totals: [DailyTotal]
        let label: (Date) -> String

        var body: some View {
            GeometryReader { geo in
                let maxVal = max(totals.map(\.totalMinutes).max() ?? 1, 1)
                let count = max(totals.count, 1)
                let slotWidth = geo.size.width / CGFloat(count)
                let barWidth = max(6, slotWidth * 0.6)
                VStack {
                    Spacer()
                    ZStack(alignment: .bottomLeading) {
                        Rectangle()
                            .fill(Color.themeTextSecondary.opacity(0.08))
                            .frame(height: 1)
                            .offset(y: -1)
                        HStack(alignment: .bottom, spacing: max(2, slotWidth * 0.4)) {
                            ForEach(totals) { day in
                                let h = CGFloat(day.totalMinutes) / CGFloat(maxVal) * max(geo.size.height - 20, 1)
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(Color.themePrimary)
                                    .frame(width: barWidth, height: h)
                                    .overlay(alignment: .bottom) {
                                        Text(label(day.date))
                                            .font(.caption2)
                                            .foregroundStyle(Color.themeTextSecondary)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                                            .frame(width: max(24, barWidth))
                                            .offset(y: 14)
                                    }
                            }
                        }
                    }
                }
            }
        }
    }
}

#if canImport(Charts)
@available(iOS 16, macOS 13, watchOS 9, *)
private struct ChartsDayBars: View {
    let totals: [DailyTotal]
    var body: some View {
        Chart(totals) { item in
            BarMark(
                x: .value("Day", item.date, unit: .day),
                y: .value("Minutes", item.totalMinutes)
            )
            .foregroundStyle(Color.themePrimary)
            .cornerRadius(4)
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 7)) { value in
                AxisGridLine().foregroundStyle(Color.themeTextSecondary.opacity(0.1))
                AxisTick().foregroundStyle(Color.themeTextSecondary.opacity(0.3))
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(shortLabel(date))
                    }
                }
                .foregroundStyle(Color.themeTextSecondary)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine().foregroundStyle(Color.themeTextSecondary.opacity(0.1))
                AxisTick().foregroundStyle(Color.themeTextSecondary.opacity(0.3))
                AxisValueLabel().foregroundStyle(Color.themeTextSecondary)
            }
        }
    }

    private func shortLabel(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.locale = .current
        fmt.setLocalizedDateFormatFromTemplate("Md")
        return fmt.string(from: date)
    }
}
#endif

// MARK: - Weekday chart

struct WeekdayChartView: View {
    let weekdayTotals: [WeekdayTotal]

    init(weekdayTotals: [WeekdayTotal]) {
        self.weekdayTotals = weekdayTotals
    }

    var body: some View {
        #if canImport(Charts)
        if #available(iOS 16, macOS 13, watchOS 9, *) {
            ChartsWeekdayBars(weekdayTotals: weekdayTotals)
        } else {
            FallbackBars(weekdayTotals: weekdayTotals)
        }
        #else
        FallbackBars(weekdayTotals: weekdayTotals)
        #endif
    }

    private struct FallbackBars: View {
        let weekdayTotals: [WeekdayTotal]
        var body: some View {
            GeometryReader { geo in
                let maxVal = max(weekdayTotals.map(\.totalMinutes).max() ?? 1, 1)
                let count = max(weekdayTotals.count, 1)
                let slotWidth = geo.size.width / CGFloat(count)
                let barWidth = max(10, slotWidth * 0.6)
                HStack(alignment: .bottom, spacing: max(4, slotWidth * 0.4)) {
                    ForEach(weekdayTotals, id: \.weekdayIndex) { item in
                        let h = CGFloat(item.totalMinutes) / CGFloat(maxVal) * max(geo.size.height - 20, 1)
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(WeekdayChartView.weekdayColor(for: item.weekdayIndex))
                            .frame(width: barWidth, height: h)
                            .overlay(alignment: .bottom) {
                                Text(item.label)
                                    .font(.caption2)
                                    .foregroundStyle(Color.themeTextSecondary)
                                    .frame(width: max(28, barWidth))
                                    .offset(y: 14)
                            }
                    }
                }
            }
        }
    }

    static func weekdayColor(for index: Int) -> Color {
        let base = Color.themeSecondary
        let alphas: [Double] = [1.0, 0.95, 0.9, 0.85, 0.8, 0.75, 0.7]
        return base.opacity(alphas[index % alphas.count])
    }
}

#if canImport(Charts)
@available(iOS 16, macOS 13, watchOS 9, *)
private struct ChartsWeekdayBars: View {
    let weekdayTotals: [WeekdayTotal]
    var body: some View {
        Chart(weekdayTotals, id: \.weekdayIndex) { item in
            BarMark(
                x: .value("Weekday", item.label),
                y: .value("Minutes", item.totalMinutes)
            )
            .foregroundStyle(WeekdayChartView.weekdayColor(for: item.weekdayIndex))
            .cornerRadius(4)
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine().foregroundStyle(Color.themeTextSecondary.opacity(0.1))
                AxisTick().foregroundStyle(Color.themeTextSecondary.opacity(0.3))
                AxisValueLabel().foregroundStyle(Color.themeTextSecondary)
            }
        }
    }
}
#endif

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

