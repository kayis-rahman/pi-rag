import Foundation

#if canImport(EventKit)
import EventKit
#endif

struct DailyBriefingEvent: Identifiable, Sendable, Equatable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
}

struct DailyBriefingItem: Identifiable, Sendable, Equatable {
    let id: UUID
    let title: String
    let dueDate: Date?
}

struct DailyBriefingSections: Sendable, Equatable {
    let day: Date
    let dueToday: [DailyBriefingItem]
    let overdue: [DailyBriefingItem]
    let waiting: [DailyBriefingItem]
    let calendarEvents: [DailyBriefingEvent]
    let isFirstRun: Bool

    var hasWork: Bool { !dueToday.isEmpty || !overdue.isEmpty || !waiting.isEmpty || !calendarEvents.isEmpty }
}

struct DailyBriefingResult: Sendable, Equatable {
    let sections: DailyBriefingSections
    let narrative: String?

    var plainText: String {
        if sections.isFirstRun { return "Welcome to Synapse. Capture your first thought to start your day." }

        var lines: [String] = []
        if sections.dueToday.isEmpty {
            lines.append(sections.waiting.isEmpty
                ? "All clear — nothing is due today."
                : "Nothing due today, \(sections.waiting.count) item\(sections.waiting.count == 1 ? "" : "s") in Waiting For.")
        } else {
            lines.append("Due today")
            lines.append(contentsOf: sections.dueToday.map { "• \($0.title)" })
        }
        if !sections.overdue.isEmpty {
            lines.append("Overdue")
            lines.append(contentsOf: sections.overdue.map { "• \($0.title)" })
        }
        if !sections.waiting.isEmpty {
            lines.append("Check on this")
            lines.append(contentsOf: sections.waiting.map { "• \($0.title)" })
        }
        return lines.joined(separator: "\n")
    }
}

@MainActor
protocol DailyBriefingCalendarProvider {
    func events(for day: Date, calendar: Calendar) async -> [DailyBriefingEvent]
}

@MainActor
struct EmptyDailyBriefingCalendarProvider: DailyBriefingCalendarProvider {
    func events(for day: Date, calendar: Calendar) async -> [DailyBriefingEvent] { [] }
}

#if canImport(EventKit)
@MainActor
final class EventKitDailyBriefingCalendarProvider: DailyBriefingCalendarProvider {
    private let store = EKEventStore()

    func events(for day: Date, calendar: Calendar) async -> [DailyBriefingEvent] {
        let status = EKEventStore.authorizationStatus(for: .event)
        guard status == .fullAccess || status == .authorized else { return [] }

        let start = calendar.startOfDay(for: day)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return [] }
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        return store.events(matching: predicate)
            .map {
                DailyBriefingEvent(
                    id: $0.eventIdentifier ?? UUID().uuidString,
                    title: $0.title,
                    startDate: $0.startDate,
                    endDate: $0.endDate,
                    isAllDay: $0.isAllDay
                )
            }
            .sorted { $0.startDate < $1.startDate }
    }
}
#endif

enum DailyBriefingComposer {
    static func sections(
        from tasks: [TaskItem],
        now: Date = .now,
        calendar: Calendar = .current,
        calendarEvents: [DailyBriefingEvent] = [],
        isFirstRun: Bool = false
    ) -> DailyBriefingSections {
        let open = tasks.filter { $0.status != .completed && $0.status != .cancelled }
        let nextActions = open.filter { $0.status == .nextAction }
        let dueToday = nextActions.filter { date in
            guard let dueDate = date.dueDate else { return false }
            return calendar.isDate(dueDate, inSameDayAs: now)
        }
        let overdue = nextActions.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate < now && !calendar.isDate(dueDate, inSameDayAs: now)
        }
        // Waiting For is always useful context in a morning briefing. A past
        // follow-up date makes it actionable, but a future follow-up still
        // belongs in the count and distinct section.
        let waiting = open.filter { $0.status == .waitingFor }

        func item(_ task: TaskItem) -> DailyBriefingItem {
            DailyBriefingItem(id: task.id, title: task.title, dueDate: task.dueDate)
        }
        return DailyBriefingSections(
            day: calendar.startOfDay(for: now),
            dueToday: dueToday.sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }.map(item),
            overdue: overdue.sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }.map(item),
            waiting: waiting.sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }.map(item),
            calendarEvents: calendarEvents,
            isFirstRun: isFirstRun
        )
    }
}

@MainActor
final class DailyBriefingService {
    static let shared = DailyBriefingService()

    private let calendarProvider: any DailyBriefingCalendarProvider

    init(calendarProvider: (any DailyBriefingCalendarProvider)? = nil) {
        self.calendarProvider = calendarProvider ?? Self.defaultCalendarProvider
    }

    static var defaultCalendarProvider: any DailyBriefingCalendarProvider {
        #if canImport(EventKit)
        EventKitDailyBriefingCalendarProvider()
        #else
        EmptyDailyBriefingCalendarProvider()
        #endif
    }

    var calendarAccessCacheKey: String {
        #if canImport(EventKit)
        String(EKEventStore.authorizationStatus(for: .event).rawValue)
        #else
        "unavailable"
        #endif
    }

    func makeBriefing(tasks: [TaskItem], now: Date = .now, isFirstRun: Bool = false) async -> DailyBriefingResult {
        let calendar = Calendar.current
        let events = await calendarProvider.events(for: now, calendar: calendar)
        let sections = DailyBriefingComposer.sections(
            from: tasks,
            now: now,
            calendar: calendar,
            calendarEvents: events,
            isFirstRun: isFirstRun
        )
        let narrative = await OnDeviceIntelligenceService.shared.briefingNarrative(for: sections)
        return DailyBriefingResult(sections: sections, narrative: narrative)
    }
}
