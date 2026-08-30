import Foundation

struct UserTaskTrendEntry: Decodable, Identifiable {
    var id: String { date }
    let date: String
    let tasksCreated: Int
    let tasksCompleted: Int
    let totalMinutes: Int

    enum CodingKeys: String, CodingKey {
        case date
        case tasksCreated = "tasks_created"
        case tasksCompleted = "tasks_completed"
        case totalMinutes = "total_minutes"
    }
}
