import XCTest
@testable import Synapse

@MainActor
final class DailyBriefingServiceTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)
    private let now = Date(timeIntervalSince1970: 1_735_776_000)

    func testDueTodayAndOverdueAreSeparate() {
        let today = TaskItem(title: "Ship update", status: .nextAction, dueDate: now.addingTimeInterval(3600))
        let overdue = TaskItem(title: "Send invoice", status: .nextAction, dueDate: now.addingTimeInterval(-86_400))
        let sections = DailyBriefingComposer.sections(from: [today, overdue], now: now, calendar: calendar)

        XCTAssertEqual(sections.dueToday.map(\.title), ["Ship update"])
        XCTAssertEqual(sections.overdue.map(\.title), ["Send invoice"])
    }

    func testNothingDueReportsWaitingCount() {
        let waiting = TaskItem(title: "Client reply", status: .waitingFor, dueDate: now.addingTimeInterval(-3600))
        let result = DailyBriefingResult(sections: DailyBriefingComposer.sections(from: [waiting], now: now, calendar: calendar), narrative: nil)
        XCTAssertEqual(result.plainText, "Nothing due today, 1 item in Waiting For.")
    }

    func testNothingDueAndNothingWaitingIsPositive() {
        let result = DailyBriefingResult(sections: DailyBriefingComposer.sections(from: [], now: now, calendar: calendar), narrative: nil)
        XCTAssertEqual(result.plainText, "All clear — nothing is due today.")
    }

    func testWaitingForAndAllDayCalendarEventStayDistinct() {
        let waiting = TaskItem(title: "Check contract", status: .waitingFor, dueDate: now.addingTimeInterval(-1))
        let event = DailyBriefingEvent(id: "all-day", title: "Conference", startDate: now, endDate: now.addingTimeInterval(86_400), isAllDay: true)
        let sections = DailyBriefingComposer.sections(from: [waiting], now: now, calendar: calendar, calendarEvents: [event])

        XCTAssertEqual(sections.waiting.map(\.title), ["Check contract"])
        XCTAssertTrue(sections.dueToday.isEmpty)
        XCTAssertTrue(sections.calendarEvents.first?.isAllDay == true)
    }

    func testTimezoneBoundariesUseSuppliedCalendar() {
        var timezoneCalendar = calendar
        timezoneCalendar.timeZone = TimeZone(secondsFromGMT: 14 * 3600)!
        let task = TaskItem(title: "Local morning", status: .nextAction, dueDate: now.addingTimeInterval(3600))
        let sections = DailyBriefingComposer.sections(from: [task], now: now, calendar: timezoneCalendar)

        XCTAssertEqual(sections.dueToday.count, 1)
    }
}
