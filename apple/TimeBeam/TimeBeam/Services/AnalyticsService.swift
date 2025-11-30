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

enum AnalyticsService {
    static func last7DaysTotals(records: [SessionRecord], calendar: Calendar = .current) -> [DailyTotal] {
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        let days = (0..<7).reversed().map { offset -> Date in
            calendar.date(byAdding: .day, value: -offset, to: startOfToday)!
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
