import XCTest
import SwiftData
@testable import Synapse

@MainActor
final class DailyBriefingPersistenceTests: XCTestCase {
    func testBriefingReadsPersistedTasksAndExcludesCompletedItems() throws {
        let marker = UUID().uuidString
        let now = Date()
        let due = TaskItem(title: "Persisted due \(marker)", status: .nextAction, dueDate: now)
        let completed = TaskItem(title: "Completed \(marker)", status: .completed, dueDate: now)
        let context = ModelContext(SynapseModelContainer.shared)
        context.insert(due)
        context.insert(completed)
        try context.save()

        let persisted = try context.fetch(FetchDescriptor<TaskItem>(predicate: #Predicate { $0.title.contains(marker) }))
        let sections = DailyBriefingComposer.sections(from: persisted, now: now)

        XCTAssertEqual(sections.dueToday.map(\.title), ["Persisted due \(marker)"])
        XCTAssertFalse(sections.dueToday.contains { $0.title.contains("Completed") })
    }

    func testBriefingUsesCurrentPersistedStatusAfterCompletion() throws {
        let marker = UUID().uuidString
        let task = TaskItem(title: "Complete me \(marker)", status: .nextAction, dueDate: .now)
        let context = ModelContext(SynapseModelContainer.shared)
        context.insert(task)
        try context.save()

        task.status = .completed
        try context.save()

        let persisted = try context.fetch(FetchDescriptor<TaskItem>(predicate: #Predicate { $0.title == "Complete me \(marker)" }))
        XCTAssertTrue(DailyBriefingComposer.sections(from: persisted).dueToday.isEmpty)
    }

    func testOfflineBriefingUsesLocalStoreAndOmitsUnavailableCalendar() async throws {
        let marker = UUID().uuidString
        let task = TaskItem(title: "Offline action \(marker)", status: .nextAction, dueDate: .now)
        let service = DailyBriefingService(calendarProvider: EmptyDailyBriefingCalendarProvider())

        let result = await service.makeBriefing(tasks: [task])

        XCTAssertEqual(result.sections.dueToday.map(\.title), ["Offline action \(marker)"])
        XCTAssertTrue(result.sections.calendarEvents.isEmpty)
    }

    func testProductionStoreRemainsConfiguredForPrivateCloudKitSync() {
        let configuration = SynapseModelContainer.configuration(isTesting: false)
        XCTAssertEqual(configuration.cloudKitContainerIdentifier, SynapseModelContainer.cloudKitContainerIdentifier)
    }
}
