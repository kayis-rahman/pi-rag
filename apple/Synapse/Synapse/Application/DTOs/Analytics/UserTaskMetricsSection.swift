import Foundation

struct UserTaskMetricsSection: Decodable {
    let totalTasks: Int
    let completedTasks: Int
    let activeTasks: Int
    let completionRate: Double
    let averageTaskDuration: Int
    let totalTimeSpent: Int

    enum CodingKeys: String, CodingKey {
        case totalTasks = "total_tasks"
        case completedTasks = "completed_tasks"
        case activeTasks = "active_tasks"
        case completionRate = "completion_rate"
        case averageTaskDuration = "average_task_duration"
        case totalTimeSpent = "total_time_spent"
    }
}
