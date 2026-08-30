import Foundation

struct UserTaskAnalyticsResponse: Decodable {
    let taskMetrics: UserTaskMetricsSection
    let taskBreakdown: UserTaskBreakdownSection
    let taskTrends: UserTaskTrendsSection
    let productivityByTask: UserProductivityByTaskSection
    let metadata: UserTaskMetadataSection

    enum CodingKeys: String, CodingKey {
        case taskMetrics = "task_metrics"
        case taskBreakdown = "task_breakdown"
        case taskTrends = "task_trends"
        case productivityByTask = "productivity_by_task"
        case metadata
    }
}
