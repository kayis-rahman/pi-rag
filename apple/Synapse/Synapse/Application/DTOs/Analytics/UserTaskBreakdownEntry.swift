import Foundation

struct UserTaskBreakdownEntry: Decodable, Identifiable {
    var id: String { taskId }
    let taskId: String
    let taskTitle: String
    let status: String
    let totalMinutes: Int
    let sessionCount: Int
    let completionDate: String?
    let createdDate: String

    enum CodingKeys: String, CodingKey {
        case taskId = "task_id"
        case taskTitle = "task_title"
        case status
        case totalMinutes = "total_minutes"
        case sessionCount = "session_count"
        case completionDate = "completion_date"
        case createdDate = "created_date"
    }
}
