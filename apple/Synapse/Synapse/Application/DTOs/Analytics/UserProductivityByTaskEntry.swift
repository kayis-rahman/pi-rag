import Foundation

struct UserProductivityByTaskEntry: Decodable, Identifiable {
    var id: String { taskId }
    let taskId: String
    let taskTitle: String
    let totalMinutes: Int
    let sessionCount: Int
    let averageSessionLength: Double
    let productivityScore: Double

    enum CodingKeys: String, CodingKey {
        case taskId = "task_id"
        case taskTitle = "task_title"
        case totalMinutes = "total_minutes"
        case sessionCount = "session_count"
        case averageSessionLength = "average_session_length"
        case productivityScore = "productivity_score"
    }
}
