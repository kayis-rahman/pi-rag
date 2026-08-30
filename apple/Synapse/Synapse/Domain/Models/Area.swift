import Foundation
import SwiftData

@Model
final class Area {
    var id: UUID = UUID()
    var name: String = ""
    var notes: String = ""
    var createdAt: Date = Date()

    @Relationship(deleteRule: .nullify, inverse: \TaskItem.areas)
    var tasks: [TaskItem]? = []

    init(name: String, notes: String = "") {
        self.name = name
        self.notes = notes
    }
}
