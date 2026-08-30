import XCTest
import SwiftData
@testable import Synapse

@MainActor
final class QuickCapturePersistenceTests: XCTestCase {
    func testCaptureSavesLocallyWithCloudKitDisabledForOfflineOperation() throws {
        let configuration = SynapseModelContainer.configuration(isTesting: true)
        XCTAssertNil(configuration.cloudKitContainerIdentifier)

        let context = ModelContext(SynapseModelContainer.shared)
        let item = CaptureService(allowsFoundationModel: false).processInboxCapture(text: "Call bank")
        try CapturePersistenceService.save(item, in: context)

        let itemID = item.id
        let saved = try context.fetch(FetchDescriptor<TaskItem>(predicate: #Predicate { $0.id == itemID }))
        XCTAssertEqual(saved.count, 1)
        XCTAssertEqual(saved.first?.title, "Call bank")
        XCTAssertEqual(saved.first?.status, .inbox)
    }

    func testRawCaptureRemainsUncategorizedUntilConfirmationIsSaved() throws {
        let marker = UUID().uuidString
        let context = ModelContext(SynapseModelContainer.shared)
        let item = TaskItem(title: "Call dentist Tuesday \(marker)", status: .inbox)

        try CapturePersistenceService.save(item, in: context)

        let itemID = item.id
        let persisted = try XCTUnwrap(
            context.fetch(FetchDescriptor<TaskItem>(predicate: #Predicate { $0.id == itemID })).first
        )
        XCTAssertEqual(persisted.status, .inbox)
        XCTAssertTrue(persisted.contextTags.isEmpty)
        XCTAssertNil(persisted.dueDate)
        XCTAssertNil(persisted.project)
        XCTAssertTrue(persisted.areas?.isEmpty ?? true)
    }

    func testRapidDuplicateCapturesRemainSeparateRecords() throws {
        let marker = UUID().uuidString
        let text = "Test \(marker)"
        let service = CaptureService(allowsFoundationModel: false)
        let context = ModelContext(SynapseModelContainer.shared)
        let first = service.processInboxCapture(text: text)
        let second = service.processInboxCapture(text: text)

        try CapturePersistenceService.save(first, in: context)
        try CapturePersistenceService.save(second, in: context)

        let saved = try context.fetch(FetchDescriptor<TaskItem>(predicate: #Predicate { $0.title == text }))
        XCTAssertEqual(saved.count, 2)
        XCTAssertEqual(Set(saved.map(\.id)).count, 2)
    }

    func testTenSequentialCapturesAreAllPersisted() throws {
        let marker = UUID().uuidString
        let context = ModelContext(SynapseModelContainer.shared)
        let service = CaptureService(allowsFoundationModel: false)

        for index in 1...10 {
            let item = service.processInboxCapture(text: "Rapid capture \(index) \(marker)")
            try CapturePersistenceService.save(item, in: context)
        }

        let saved = try context.fetch(FetchDescriptor<TaskItem>(predicate: #Predicate { $0.title.contains(marker) }))
        XCTAssertEqual(saved.count, 10)
        XCTAssertTrue(saved.allSatisfy { $0.status == .inbox })
    }

    func testProductionConfigurationUsesPrivateCloudKitForReconnectSync() {
        let configuration = SynapseModelContainer.configuration(isTesting: false)

        XCTAssertEqual(configuration.cloudKitContainerIdentifier, SynapseModelContainer.cloudKitContainerIdentifier)
        XCTAssertFalse(configuration.isStoredInMemoryOnly)
    }
}
