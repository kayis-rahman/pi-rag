import Foundation
import SwiftData

/// A single actionable or captured item in the GTD system.
///
/// Inbox, Next Actions, Waiting For, and Someday / Maybe are projections over
/// this entity's `status`; a task therefore keeps one stable identity as it
/// moves through the workflow.
@Model
final class GTDTask {
    var id: UUID = UUID()
    var title: String = ""
    var notes: String = ""

    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var dueDate: Date?
    var completedAt: Date?

    private var statusRawValue: String = GTDStatus.inbox.rawValue
    var tags: [String] = []
    var sortOrder: Double = 0

    @Relationship(deleteRule: .nullify, inverse: \Project.nextActions)
    var project: Project?

    @Relationship(deleteRule: .nullify, inverse: \Area.tasks)
    var areas: [Area] = []

    var status: GTDStatus {
        get { GTDStatus(rawValue: statusRawValue) ?? .inbox }
        set {
            statusRawValue = newValue.rawValue
            if newValue == .completed {
                completedAt = completedAt ?? Date()
            } else {
                completedAt = nil
            }
            updatedAt = Date()
        }
    }

    init(
        title: String,
        notes: String = "",
        status: GTDStatus = .inbox,
        dueDate: Date? = nil,
        tags: [String] = [],
        project: Project? = nil,
        areas: [Area] = []
    ) {
        self.title = title
        self.notes = notes
        self.dueDate = dueDate
        self.tags = tags
        self.project = project
        self.areas = areas
        self.statusRawValue = status.rawValue
    }
}
