#if os(iOS)
import SwiftUI
import Charts

struct TaskAnalyticsView: View {
    @EnvironmentObject var taskService: TaskService
    @State private var analyticsData: TaskAnalyticsData?
    @State private var isLoading = false
    @State private var selectedTimeRange = "month"
    @State private var errorMessage: String?

    let timeRanges = ["week", "month", "quarter", "year"]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Time range picker
                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach(timeRanges, id: \.self) { range in
                            Text(range.capitalized).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .onChange(of: selectedTimeRange) { _ in
                        loadAnalytics()
                    }

                    if isLoading {
                        ProgressView("Loading analytics...")
                            .frame(maxWidth: .infinity, maxHeight: 200)
                    } else if let data = analyticsData {
                        // Task Metrics Overview
                        TaskMetricsOverviewView(metrics: data.metrics)

                        // Task Completion Trends
                        TaskCompletionTrendsView(trends: data.trends)

                        // Productivity by Task
                        ProductivityByTaskView(productivity: data.productivity)

                        // Task Breakdown
                        TaskBreakdownView(breakdown: data.breakdown)
                    } else if let error = errorMessage {
                        Text("Error: \(error)")
                            .foregroundColor(.red)
                            .padding()
                    } else {
                        Text("No analytics data available")
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Task Analytics")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                loadAnalytics()
            }
        }
    }

    private func loadAnalytics() {
        isLoading = true
        errorMessage = nil

        _Concurrency.Task {
            do {
                // This would call the backend analytics API
                // For now, create mock data
                try await _Concurrency.Task.sleep(for: .seconds(1))

                analyticsData = TaskAnalyticsData(
                    metrics: TaskMetrics(
                        totalTasks: 24,
                        completedTasks: 18,
                        activeTasks: 6,
                        completionRate: 75.0,
                        averageTaskDuration: 180, // minutes
                        totalTimeSpent: 4320 // minutes
                    ),
                    trends: TaskTrends(
                        data: [
                            TaskTrendData(date: "2024-01-01", tasksCreated: 2, tasksCompleted: 1, totalMinutes: 120),
                            TaskTrendData(date: "2024-01-02", tasksCreated: 1, tasksCompleted: 2, totalMinutes: 180),
                            TaskTrendData(date: "2024-01-03", tasksCreated: 3, tasksCompleted: 1, totalMinutes: 240)
                        ]
                    ),
                    productivity: TaskProductivity(
                        data: [
                            TaskProductivityData(taskId: UUID(), taskTitle: "Project Alpha", totalMinutes: 480, sessionCount: 8, averageSessionLength: 60, productivityScore: 85.5),
                            TaskProductivityData(taskId: UUID(), taskTitle: "Bug Fixes", totalMinutes: 240, sessionCount: 6, averageSessionLength: 40, productivityScore: 72.3),
                            TaskProductivityData(taskId: UUID(), taskTitle: "Documentation", totalMinutes: 180, sessionCount: 4, averageSessionLength: 45, productivityScore: 68.1)
                        ]
                    ),
                    breakdown: TaskBreakdown(
                        data: [
                            TaskBreakdownData(taskId: UUID(), taskTitle: "Project Alpha", status: "completed", totalMinutes: 480, sessionCount: 8, completionDate: "2024-01-15", createdDate: "2024-01-01"),
                            TaskBreakdownData(taskId: UUID(), taskTitle: "Bug Fixes", status: "in_progress", totalMinutes: 240, sessionCount: 6, completionDate: nil, createdDate: "2024-01-05"),
                            TaskBreakdownData(taskId: UUID(), taskTitle: "Documentation", status: "completed", totalMinutes: 180, sessionCount: 4, completionDate: "2024-01-10", createdDate: "2024-01-03")
                        ]
                    )
                )

                isLoading = false
            } catch {
                errorMessage = "Failed to load analytics"
                isLoading = false
            }
        }
    }
}

// MARK: - Supporting Views

private struct TaskMetricsOverviewView: View {
    let metrics: TaskMetrics

    var body: some View {
        VStack(spacing: 16) {
            Text("Overview")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                MetricCard(title: "Total Tasks", value: "\(metrics.totalTasks)", icon: "checklist")
                MetricCard(title: "Completed", value: "\(metrics.completedTasks)", icon: "checkmark.circle", color: .green)
                MetricCard(title: "Active", value: "\(metrics.activeTasks)", icon: "clock", color: .blue)
                MetricCard(title: "Completion Rate", value: "\(Int(metrics.completionRate))%", icon: "percent", color: .orange)
                MetricCard(title: "Avg Duration", value: formatDuration(metrics.averageTaskDuration), icon: "timer")
                MetricCard(title: "Total Time", value: formatDuration(metrics.totalTimeSpent), icon: "chart.bar")
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.horizontal)
    }

    private func formatDuration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        } else {
            return "\(mins)m"
        }
    }
}

private struct TaskCompletionTrendsView: View {
    let trends: TaskTrends

    var body: some View {
        VStack(spacing: 16) {
            Text("Completion Trends")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

            Chart(trends.data, id: \.date) { data in
                BarMark(
                    x: .value("Date", data.date),
                    y: .value("Tasks Created", data.tasksCreated)
                )
                .foregroundStyle(.blue)

                BarMark(
                    x: .value("Date", data.date),
                    y: .value("Tasks Completed", -data.tasksCompleted) // Negative for below axis
                )
                .foregroundStyle(.green)
            }
            .frame(height: 200)
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
}

private struct ProductivityByTaskView: View {
    let productivity: TaskProductivity

    var body: some View {
        VStack(spacing: 16) {
            Text("Productivity by Task")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

            ForEach(productivity.data.sorted { $0.totalMinutes > $1.totalMinutes }) { data in
                HStack {
                    VStack(alignment: .leading) {
                        Text(data.taskTitle)
                            .font(.subheadline)
                            .fontWeight(.medium)

                        HStack {
                            Text("\(data.totalMinutes)m total")
                            Text("•")
                            Text("\(data.sessionCount) sessions")
                            Text("•")
                            Text("Score: \(Int(data.productivityScore))")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }

                    Spacer()

                    CircularProgressView(progress: data.productivityScore / 100)
                        .frame(width: 40, height: 40)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
}

private struct TaskBreakdownView: View {
    let breakdown: TaskBreakdown

    var body: some View {
        VStack(spacing: 16) {
            Text("Task Breakdown")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

            ForEach(breakdown.data) { data in
                HStack {
                    VStack(alignment: .leading) {
                        Text(data.taskTitle)
                            .font(.subheadline)
                            .fontWeight(.medium)

                        HStack {
                            Text(data.status.capitalized)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(statusColor(for: data.status).opacity(0.2))
                                .foregroundColor(statusColor(for: data.status))
                                .clipShape(Capsule())

                            Text("•")
                            Text("\(data.totalMinutes)m")
                            Text("•")
                            Text("\(data.sessionCount) sessions")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }

                    Spacer()

                    if let completionDate = data.completionDate {
                        Text("✓ \(completionDate)")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.horizontal)
    }

    private func statusColor(for status: String) -> Color {
        switch status {
        case "completed": return .green
        case "in_progress": return .blue
        case "todo": return .orange
        default: return .gray
        }
    }
}

// MARK: - Supporting Components

private struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    var color: Color = .primary

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
}

private struct CircularProgressView: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 4)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.blue, lineWidth: 4)
                .rotationEffect(.degrees(-90))
        }
    }
}

// MARK: - Data Models

struct TaskAnalyticsData {
    let metrics: TaskMetrics
    let trends: TaskTrends
    let productivity: TaskProductivity
    let breakdown: TaskBreakdown
}

struct TaskMetrics {
    let totalTasks: Int
    let completedTasks: Int
    let activeTasks: Int
    let completionRate: Double
    let averageTaskDuration: Int // minutes
    let totalTimeSpent: Int // minutes
}

struct TaskTrends {
    let data: [TaskTrendData]
}

struct TaskTrendData {
    let date: String
    let tasksCreated: Int
    let tasksCompleted: Int
    let totalMinutes: Int
}

struct TaskProductivity {
    let data: [TaskProductivityData]
}

struct TaskProductivityData: Identifiable {
    let id = UUID()
    let taskId: UUID
    let taskTitle: String
    let totalMinutes: Int
    let sessionCount: Int
    let averageSessionLength: Double
    let productivityScore: Double
}

struct TaskBreakdown {
    let data: [TaskBreakdownData]
}

struct TaskBreakdownData: Identifiable {
    let id = UUID()
    let taskId: UUID
    let taskTitle: String
    let status: String
    let totalMinutes: Int
    let sessionCount: Int
    let completionDate: String?
    let createdDate: String
}

#Preview {
    TaskAnalyticsView()
        .environmentObject(TaskService())
}
#endif