import SwiftUI
#if canImport(Charts)
import Charts
#endif

// MARK: - Public helpers shared by charts

public struct WeekdayTotal: Identifiable, Equatable {
    // 0 = Monday ... 6 = Sunday
    public let id: Int
    public let weekdayIndex: Int
    public let label: String
    public let totalMinutes: Int

    public init(id: Int, weekdayIndex: Int, label: String, totalMinutes: Int) {
        self.id = id
        self.weekdayIndex = weekdayIndex
        self.label = label
        self.totalMinutes = totalMinutes
    }
}

public enum AnalyticsScope: String, CaseIterable, Identifiable {
    case week = "Week"
    case month = "Month"
    case all = "All"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .week: return "7.circle"
        case .month: return "calendar"
        case .all: return "infinity"
        }
    }
}

public enum AnalyticsGrouping: String, CaseIterable, Identifiable {
    case byDay = "By Day"
    case byWeekday = "By Weekday"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .byDay: return "chart.bar"
        case .byWeekday: return "square.grid.3x3"
        }
    }
}

public struct AnalyticsView: View {
    @EnvironmentObject private var logger: SessionLogger
    @Environment(\.dismiss) private var dismiss

    @State private var scope: AnalyticsScope = .week
    @State private var grouping: AnalyticsGrouping = .byDay
    @State private var seededMockData = false

    public init() {}

    public var body: some View {
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
            } else {
                // Fallback: no NavigationStack prior to watchOS 9
                content
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
            #endif
        }
        .onAppear {
            if !seededMockData, logger.records.isEmpty {
                seedMockDataLastMonth()
                seededMockData = true
            }
        }
    }

    // MARK: - Content

    private var content: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerCard
                chartAndFiltersCard
                streakCard
                topWindowCard
                mockDataCard
            }
            .padding()
        }
        .background(Color.themeBackground.opacity(0.4))
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
                // Filters with cross-platform styling
                Segmented(items: AnalyticsScope.allCases, selection: $scope) { s in
                    Label(s.rawValue, systemImage: s.icon)
                }
                Segmented(items: AnalyticsGrouping.allCases, selection: $grouping) { g in
                    Label(g.rawValue, systemImage: g.icon)
                }

                // Title + legend
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

                // Chart
                if grouping == .byDay {
                    DayChartView(totals: totalsForScopeByDay())
                        .frame(height: 220)
                } else {
                    WeekdayChartView(weekdayTotals: totalsForScopeByWeekday())
                        .frame(height: 220)
                }

                // Footnote + average
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
            let s = AnalyticsService.productiveStreak(records: filteredRecordsForScope())
            HStack(spacing: 12) {
                IconBadge(systemName: "flame.fill", color: .themePrimary)
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
            let window = AnalyticsService.topProductiveWindow(records: filteredRecordsForScope(), windowHours: 2)
            HStack(spacing: 12) {
                IconBadge(systemName: "clock.fill", color: .themeSecondary)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Top Time of Day")
                        .font(.headline)
                        .foregroundStyle(Color.themeTextPrimary)
                    Text(windowText(window))
                        .foregroundStyle(Color.themeTextSecondary.opacity(0.95))
                }
                Spacer()
            }
        }
    }

    private var mockDataCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                Text("Mock Data")
                    .font(.headline)
                    .foregroundStyle(Color.themeTextPrimary)
                Text("Populate the last month with synthetic sessions to preview charts.")
                    .font(.footnote)
                    .foregroundStyle(Color.themeTextSecondary.opacity(0.95))
                HStack {
                    Button {
                        seedMockDataLastMonth()
                    } label: {
                        Label("Generate Last Month", systemImage: "sparkles")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.themePrimary)

                    Button(role: .destructive) {
                        logger.clear()
                    } label: {
                        Label("Clear Data", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                }
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
        let records = filteredRecordsForScope()
        let cal = Calendar.current

        switch scope {
        case .week:
            return AnalyticsService.last7DaysTotals(records: records, calendar: cal)
        case .month:
            return lastNDaysTotals(records: records, days: 30, calendar: cal)
        case .all:
            return totalsForAllByDay(records: records, calendar: cal)
        }
    }

    private func totalsForScopeByWeekday() -> [WeekdayTotal] {
        let records = filteredRecordsForScope()
        return weekdayTotals(records: records)
    }

    private func totalMinutesForScope() -> Int {
        filteredRecordsForScope().filter { $0.isProductive }.reduce(0) { $0 + Int($1.duration / 60.0) }
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
            DailyTotal(id: day, date: day, totalMinutes: totals[day, default: 0])
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
                id: i,
                weekdayIndex: i,
                label: labels[i].isEmpty ? defaultWeekdayLabel(i) : labels[i],
                totalMinutes: totals[i]
            )
        }
    }

    private func defaultWeekdayLabel(_ idxMon0: Int) -> String {
        ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"][idxMon0]
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

    // MARK: - Mock data

    private func seedMockDataLastMonth() {
        let cal = Calendar.current
        let now = Date()
        var newRecords: [SessionRecord] = []

        for dayOffset in 0..<30 {
            guard let day = cal.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            let base = cal.startOfDay(for: day)

            let sessionsToday = Int.random(in: 0...4)
            for _ in 0..<sessionsToday {
                let hour = weightedHour()
                let minute = [0, 10, 20, 30, 40, 50].randomElement() ?? 0

                var comps = DateComponents()
                comps.hour = hour
                comps.minute = minute
                let start = cal.date(byAdding: comps, to: base) ?? base.addingTimeInterval(TimeInterval(hour * 3600 + minute * 60))

                let durationMin = [20, 25, 30, 35, 40, 45, 50, 55, 60].randomElement() ?? 25
                let record = SessionRecord(startedAt: start, duration: TimeInterval(durationMin * 60), kind: .work)
                newRecords.append(record)
            }
        }
        for r in newRecords.sorted(by: { $0.startedAt < $1.startedAt }) {
            logger.add(record: r)
        }
    }

    private func weightedHour() -> Int {
        let buckets: [(ClosedRange<Int>, Int)] = [
            (8...12, 5), (13...16, 4), (17...20, 2), (6...7, 2), (0...5, 1), (21...23, 1)
        ]
        let totalWeight = buckets.map { $0.1 }.reduce(0, +)
        let pick = Int.random(in: 1...totalWeight)
        var cumulative = 0
        for (range, weight) in buckets {
            cumulative += weight
            if pick <= cumulative {
                return Int.random(in: range)
            }
        }
        return Int.random(in: 8...12)
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
        // Segmented style is unavailable on watchOS; use default/inline
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

public struct DayChartView: View {
    let totals: [DailyTotal]

    public init(totals: [DailyTotal]) { self.totals = totals }

    public var body: some View {
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

public struct WeekdayChartView: View {
    let weekdayTotals: [WeekdayTotal]

    public init(weekdayTotals: [WeekdayTotal]) {
        self.weekdayTotals = weekdayTotals
    }

    public var body: some View {
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

    // Static helper returning a plain Color (no gradient)
    public static func weekdayColor(for index: Int) -> Color {
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
