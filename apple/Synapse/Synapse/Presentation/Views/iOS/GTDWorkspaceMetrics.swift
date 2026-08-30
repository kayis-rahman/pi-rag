import Foundation

enum GTDWorkspaceFilter: String, CaseIterable, Identifiable {
    case active
    case completed
    case archived

    var id: String { rawValue }
    var title: String {
        switch self {
        case .active: "Active"
        case .completed: "Completed"
        case .archived: "Archived"
        }
    }
}

struct GTDProjectMetrics: Equatable {
    let total: Int
    let completed: Int

    var progress: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }

    var remaining: Int { max(total - completed, 0) }
}

enum GTDWorkspaceMetrics {
    enum AreaFilter: Equatable {
        case all
        case uncategorized
        case area(UUID)
    }

    static func projects(_ projects: [Project], matching filter: GTDWorkspaceFilter) -> [Project] {
        projects.filter { project in
            switch filter {
            case .active: !project.isArchived && project.status == .active
            case .completed: !project.isArchived && project.status == .completed
            case .archived: project.isArchived
            }
        }
    }

    static func projectMetrics(tasks: [TaskItem]) -> GTDProjectMetrics {
        GTDProjectMetrics(total: tasks.count, completed: tasks.filter { $0.status == .completed }.count)
    }

    static func tasks(in area: Area, from tasks: [TaskItem]) -> [TaskItem] {
        tasks.filter { task in task.areas?.contains { $0.id == area.id } == true }
    }

    static func tasks(matching filter: AreaFilter, areas: [Area], from tasks: [TaskItem]) -> [TaskItem] {
        switch filter {
        case .all:
            return tasks
        case .uncategorized:
            return tasks.filter { $0.areas?.isEmpty != false }
        case .area(let areaID):
            guard let area = areas.first(where: { $0.id == areaID }) else { return [] }
            return Self.tasks(in: area, from: tasks)
        }
    }

    static func openTasks(in area: Area, from tasks: [TaskItem]) -> [TaskItem] {
        Self.tasks(in: area, from: tasks).filter { $0.status != .completed && $0.status != .cancelled }
    }
}
