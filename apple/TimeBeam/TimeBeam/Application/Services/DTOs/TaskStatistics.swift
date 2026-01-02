import Foundation

public struct TaskStatistics {

    public let totalTasks: Int

    public let todoCount: Int

    public let inProgressCount: Int

    public let completedCount: Int

    public let completionRate: Double



    public init(totalTasks: Int = 0,

                todoCount: Int = 0,

                inProgressCount: Int = 0,

                completedCount: Int = 0) {

        self.totalTasks = totalTasks

        self.todoCount = todoCount

        self.inProgressCount = inProgressCount

        self.completedCount = completedCount

        self.completionRate = totalTasks > 0 ? Double(completedCount) / Double(totalTasks) : 0.0

    }

}



// MARK: - Task Extensions



extension Array where Element == UserTask {

    public func filtered(by filter: TaskFilter) -> [UserTask] {

        var result = self



        // Filter by status
