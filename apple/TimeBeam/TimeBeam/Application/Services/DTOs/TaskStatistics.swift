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
        // Filter by status

        if let status = filter.status {

            result = result.filter { $0.status == status }

        }



        // Filter by search text

        if let searchText = filter.searchText?.lowercased(), !searchText.isEmpty {

            result = result.filter {

                $0.title.lowercased().contains(searchText) ||

                ($0.description?.lowercased().contains(searchText) ?? false)

            }

        }



        // Apply pagination

        let startIndex = Swift.min(filter.offset, result.count)

        let endIndex = Swift.min(startIndex + filter.limit, result.count)

        result = Array(result[startIndex..<endIndex])



        return result

    }



    public func statistics() -> TaskStatistics {

        let todoCount = filter { $0.status == .todo }.count

        let inProgressCount = filter { $0.status == .inProgress }.count

        let completedCount = filter { $0.status == .completed }.count



        return TaskStatistics(

            totalTasks: count,

            todoCount: todoCount,

            inProgressCount: inProgressCount,

            completedCount: completedCount

        )

    }



    public func sortedByStatus() -> [UserTask] {

        return sorted { (task1, task2) -> Bool in

            // Sort by status priority: todo, inProgress, completed

            let statusOrder: [UserTask.Status] = [.todo, .inProgress, .completed]

            let order1 = statusOrder.firstIndex(of: task1.status) ?? statusOrder.count

            let order2 = statusOrder.firstIndex(of: task2.status) ?? statusOrder.count



            if order1 != order2 {

                return order1 < order2

            }



            // Within same status, sort by creation date (newest first)

            return task1.createdAt > task2.createdAt

        }

    }



    // Filter method

    private func filter(_ isIncluded: (Element) throws -> Bool) rethrows -> [UserTask] {

        return try self.filter(isIncluded)

    }

}
