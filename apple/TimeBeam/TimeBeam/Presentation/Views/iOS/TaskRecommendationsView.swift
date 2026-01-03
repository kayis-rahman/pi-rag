#if os(iOS)
import SwiftUI

struct TaskRecommendationsView: View {
    @ObservedObject var timer: PomodoroTimer
    @ObservedObject var taskService: TaskService
    @State private var recommendedTasks: [UserTask] = []

    var body: some View {
        VStack(spacing: 8) {
            Text("Recommended Tasks")
                .font(.caption)
                .foregroundColor(.secondary)

            if recommendedTasks.isEmpty {
                Text("No recommendations yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}
#endif
