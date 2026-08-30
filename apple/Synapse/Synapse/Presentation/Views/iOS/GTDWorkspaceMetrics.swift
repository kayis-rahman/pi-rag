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
        tasks.filter { task in
            task.areas?.contains { $0.id == area.id } == true
                || task.contextTags.contains { tag in
                    tag.caseInsensitiveCompare("area:\(area.name)") == .orderedSame
                }
        }
    }

    static func openTasks(in area: Area, from tasks: [TaskItem]) -> [TaskItem] {
        Self.tasks(in: area, from: tasks).filter { $0.status != .completed && $0.status != .cancelled }
    }
}
