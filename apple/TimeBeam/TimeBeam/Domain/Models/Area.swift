import Foundation
import SwiftData

@Model
final class Area {
    var id: UUID = UUID()
    var name: String = ""
    var notes: String = ""
    var createdAt: Date = Date()

    @Relationship(deleteRule: .nullify, inverse: \GTDTask.areas)
    var tasks: [GTDTask] = []

    init(name: String, notes: String = "") {
        self.name = name
        self.notes = notes
    }
}
