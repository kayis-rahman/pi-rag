import Foundation
import SwiftData

@Model
final class GTDTask {
    var id: UUID = UUID()
    var title: String = ""
    var notes: String = ""
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var dueDate: Date?
    var completedAt: Date?
    var statusRawValue: String = GTDStatus.inbox.rawValue
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
            completedAt = newValue == .completed ? (completedAt ?? Date()) : nil
            updatedAt = Date()
        }
    }

    init(title: String, notes: String = "", status: GTDStatus = .inbox, dueDate: Date? = nil, tags: [String] = [], project: Project? = nil, areas: [Area] = []) {
        self.title = title
        self.notes = notes
        self.statusRawValue = status.rawValue
        self.dueDate = dueDate
        self.tags = tags
        self.project = project
        self.areas = areas
    }
}
