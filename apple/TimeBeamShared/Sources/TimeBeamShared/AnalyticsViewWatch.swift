import SwiftUI
#if canImport(Charts)
import Charts
#endif

#if os(watchOS)
public struct AnalyticsViewWatch: View {
    @EnvironmentObject private var logger: SessionLogger
    @Environment(\.dismiss) private var dismiss

    @State private var scope: AnalyticsScope = .week
    @State private var grouping: AnalyticsGrouping = .byDay
    @State private var seededMockData = false

    public init() {}

    public var body: some View {
        Group {
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
                content
            }
        }
        .onAppear {
            if !seededMockData, logger.records.isEmpty {
                seedMockDataLastMonth()
                seededMockData = true
            }
        }
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 12) {
                headerCard
                chartAndFiltersCard
                streakCard
                topWindowCard
                mockDataCard
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color.themeBackground.opacity(0.4))
    }

    // MARK: - Cards

    private var headerCard: some View {
        WatchCard {
            HStack(spacing: 12) {
                ActivityRing(progress: ringProgress, size: 44)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Analytics")
                        .font(.headline)
                        .foregroundStyle(Color.themeTextPrimary)
                    Text(subtitleForScope())
                        .font(.caption2)
                        .foregroundStyle(Color.themeTextSecondary.opacity(0.9))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(totalMinutesForScope())m")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.themePrimary)
                    Text("Focused")
                        .font(.caption2)
                        .foregroundStyle(Color.themeTextSecondary.opacity(0.9))
                }
            }
        }
    }

    private var chartAndFiltersCard: some View {
        WatchCard {
            VStack(alignment: .leading, spacing: 8) {
                // watchOS-safe pickers (no segmented style)
                Picker("Range", selection: $scope) {
                    ForEach(AnalyticsScope.allCases) { s in
                        Label(s.rawValue, systemImage: s.icon).tag(s)
                    }
                }
                .labelsHidden()

                Picker("Group", selection: $grouping) {
                    ForEach(AnalyticsGrouping.allCases) { g in
                        Label(g.rawValue, systemImage: g.icon).tag(g)
                    }
                }
                .labelsHidden()

                HStack {
                    Text(chartTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.themeTextPrimary)
                    Spacer()
                }

                if grouping == .byDay {
                    DayChartView(totals: totalsForScopeByDay())
                        .frame(height: 160)
                } else {
                    WeekdayChartView(weekdayTotals: totalsForScopeByWeekday())
                        .frame(height: 160)
                }

                HStack {
                    Text(footnoteForScope())
                        .font(.caption2)
                        .foregroundStyle(Color.themeTextSecondary.opacity(0.9))
                    Spacer()
                    Text(avgForScopeText())
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(Color.themeSecondary)
                }
            }
        }
    }

    private var streakCard: some View {
        WatchCard {
            let s = AnalyticsService.productiveStreak(records: filteredRecordsForScope())
            HStack(spacing: 8) {
                IconBadge(systemName: "flame.fill", color: .themePrimary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Streak")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.themeTextPrimary)
                    Text(s == 0 ? "No current streak" :
                         (s == 1 ? "1 day in a row" : "\(s) days in a row"))
                        .font(.caption2)
                        .foregroundStyle(Color.themeTextSecondary.opacity(0.95))
                }
                Spacer()
            }
        }
    }

    private var topWindowCard: some View {
        WatchCard {
            let window = AnalyticsService.topProductiveWindow(records: filteredRecordsForScope(), windowHours: 2)
            HStack(spacing: 8) {
                IconBadge(systemName: "clock.fill", color: .themeSecondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Top Time")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.themeTextPrimary)
                    Text(windowText(window))
                        .font(.caption2)
                        .foregroundStyle(Color.themeTextSecondary.opacity(0.95))
                }
                Spacer()
            }
        }
    }

    private var mockDataCard: some View {
        WatchCard {
            VStack(alignment: .leading, spacing: 6) {
                Text("Mock Data")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.themeTextPrimary)
                Text("Generate last month of synthetic sessions.")
                    .font(.caption2)
                    .foregroundStyle(Color.themeTextSecondary.opacity(0.95))
                HStack {
                    Button {
                        seedMockDataLastMonth()
                    } label: {
                        Label("Generate", systemImage: "sparkles")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.themePrimary)

                    Button(role: .destructive) {
                        logger.clear()
                    } label: {
                        Label("Clear", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    // MARK: - Data prep (same logic as main AnalyticsView)

    private var chartTitle: String {
        switch scope {
        case .week: return grouping == .byDay ? "Last 7 Days" : "Last 7 by Weekday"
        case .month: return grouping == .byDay ? "Last 30 Days" : "Last 30 by Weekday"
        case .all: return grouping == .byDay ? "All Time (by Day)" : "All Time (by Weekday)"
        }
    }

    private func footnoteForScope() -> String {
        grouping == .byDay ? "Minutes per day" : "Minutes by weekday"
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

// A simpler card for watchOS that avoids .regularMaterial before watchOS 10
private struct WatchCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            content
        }
        .padding(12)
        .background(backgroundStyle)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.themeTextSecondary.opacity(0.16), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var backgroundStyle: some View {
        let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)
        if #available(watchOS 10.0, *) {
            shape.fill(.regularMaterial)
        } else {
            shape.fill(Color.themeBackground.opacity(0.6))
        }
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
#endif
