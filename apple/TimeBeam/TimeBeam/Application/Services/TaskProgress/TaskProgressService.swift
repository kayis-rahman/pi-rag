import Foundation

/// Service for calculating task progress statistics
/// Handles completed sessions, estimated sessions, and time tracking
final class TaskProgressService {
    
    /// Calculates progress for a specific task
    static func getTaskProgress(_ task: UserTask) -> TaskProgress {
        // For now, return a basic progress object
        // In production, this would fetch from session records
        return TaskProgress(
            taskId: task.id,
            completedSessions: 0,
            totalEstimatedSessions: 10, // Default estimate
            totalTimeSpent: 0,
            isAutoCompletable: false
        )
    }
}
