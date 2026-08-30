import Foundation
import SwiftData

/// Deterministic relationship data for the isolated `-ui-testing` store only.
@MainActor
enum GTDWorkspaceUITestData {
    static func seedProjectsAndAreasIfRequested(in context: ModelContext) throws {
        let environment = ProcessInfo.processInfo.environment
        guard SynapseModelContainer.isTestingProcess,
              environment["SYNAPSE_UI_TEST_SEED_PROJECTS_AREAS"] == "1"
        else { return }

        let projectTitle = "UI Test Project"
        let existing = try context.fetch(
            FetchDescriptor<Project>(predicate: #Predicate { $0.title == projectTitle })
        )
        guard existing.isEmpty else { return }

        let project = Project(title: projectTitle, desiredOutcome: "A verified project relationship")
        let emptyProject = Project(title: "UI Test Empty Project", desiredOutcome: "An outcome without actions")
        let primaryArea = Area(name: "UI Test Area", notes: "The primary test responsibility")
        let otherArea = Area(name: "UI Test Other Area", notes: "Must not leak into the primary area")
        let nextAction = TaskItem(
            title: "UI Test Project Next Action",
            status: .nextAction,
            project: project,
            areas: [primaryArea]
        )
        let completedAction = TaskItem(
            title: "UI Test Project Completed Action",
            status: .completed,
            project: project,
            areas: [primaryArea]
        )
        let unrelatedAction = TaskItem(
            title: "UI Test Other Area Action",
            status: .nextAction,
            areas: [otherArea]
        )

        context.insert(project)
        context.insert(emptyProject)
        context.insert(primaryArea)
        context.insert(otherArea)
        context.insert(nextAction)
        context.insert(completedAction)
        context.insert(unrelatedAction)
        try context.save()
    }
}
