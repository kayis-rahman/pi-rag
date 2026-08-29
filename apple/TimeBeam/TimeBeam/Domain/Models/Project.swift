import Foundation
import SwiftData

enum ProjectStatus: String, Codable, CaseIterable, Sendable {
    case active
    case completed
    case dropped
}

/// A desired outcome that requires more than one action.
@Model
final class Project {
    var id: UUID = UUID()
    var title: String = ""
    var outcome: String = ""
    var notes: String = ""
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var completedAt: Date?
    var statusRawValue: String = ProjectStatus.active.rawValue

    @Relationship(deleteRule: .nullify, inverse: \GTDTask.project)
    var nextActions: [GTDTask] = []

    var status: ProjectStatus {
        get { ProjectStatus(rawValue: statusRawValue) ?? .active }
        set {
            statusRawValue = newValue.rawValue
            completedAt = newValue == .completed ? (completedAt ?? Date()) : nil
            updatedAt = Date()
        }
    }

    init(title: String, outcome: String = "", notes: String = "") {
        self.title = title
        self.outcome = outcome
        self.notes = notes
    }
}
