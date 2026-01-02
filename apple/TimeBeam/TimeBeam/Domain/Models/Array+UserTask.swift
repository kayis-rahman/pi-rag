import Foundation

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

}
