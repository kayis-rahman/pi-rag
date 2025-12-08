import Foundation

// Typealias for backward compatibility with existing code
public typealias UserTask = Task

public struct Task: Codable, Identifiable, Equatable {
    public enum Status: String, Codable {
        case todo, inProgress = "in_progress", completed

        public var displayName: String {
            switch self {
            case .todo: return "To Do"
            case .inProgress: return "In Progress"
            case .completed: return "Completed"
            }
        }

        public var isActive: Bool {
            return self == .todo || self == .inProgress
        }

        public var isCompleted: Bool {
            return self == .completed
        }
    }

    public let id: UUID
    public let userId: UUID
    public let title: String
    public let description: String?
    public let status: Status
    public let createdAt: Date
    public let updatedAt: Date

    public init(id: UUID = UUID(),
                userId: UUID,
                title: String,
                description: String? = nil,
                status: Status = .todo,
                createdAt: Date = Date(),
                updatedAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.title = title
        self.description = description
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // Domain methods
    public var isActive: Bool {
        return status.isActive
    }

    public var isCompleted: Bool {
        return status.isCompleted
    }

    public func withTitle(_ newTitle: String) -> Task {
        return Task(id: id, userId: userId, title: newTitle, description: description,
                   status: status, createdAt: createdAt, updatedAt: Date())
    }

    public func withDescription(_ newDescription: String?) -> Task {
        return Task(id: id, userId: userId, title: title, description: newDescription,
                   status: status, createdAt: createdAt, updatedAt: Date())
    }

    public func withStatus(_ newStatus: Status) -> Task {
        return Task(id: id, userId: userId, title: title, description: description,
                   status: newStatus, createdAt: createdAt, updatedAt: Date())
    }

    // Validation
    public func validate() throws {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TaskValidationError.emptyTitle
        }
        guard title.count <= 255 else {
            throw TaskValidationError.titleTooLong
        }
        if let description = description {
            guard description.count <= 1000 else {
                throw TaskValidationError.descriptionTooLong
            }
        }
    }
}

// MARK: - Validation Errors

public enum TaskValidationError: LocalizedError {
    case emptyTitle
    case titleTooLong
    case descriptionTooLong

    public var errorDescription: String? {
        switch self {
        case .emptyTitle:
            return "Task title cannot be empty"
        case .titleTooLong:
            return "Task title cannot exceed 255 characters"
        case .descriptionTooLong:
            return "Task description cannot exceed 1000 characters"
        }
    }
}

// MARK: - Task Filter

public struct TaskFilter {
    public var status: Task.Status?
    public var searchText: String?
    public var limit: Int = 50
    public var offset: Int = 0

    public init(status: Task.Status? = nil,
                searchText: String? = nil,
                limit: Int = 50,
                offset: Int = 0) {
        self.status = status
        self.searchText = searchText
        self.limit = limit
        self.offset = offset
    }

    public var hasFilters: Bool {
        return status != nil || !(searchText?.isEmpty ?? true)
    }
}

// MARK: - Task Statistics

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

extension Array where Element == Task {
    public func filtered(by filter: TaskFilter) -> [Task] {
        var result = self

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

    public func sortedByStatus() -> [Task] {
        return sorted { (task1, task2) -> Bool in
            // Sort by status priority: todo, inProgress, completed
            let statusOrder: [Task.Status] = [.todo, .inProgress, .completed]
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