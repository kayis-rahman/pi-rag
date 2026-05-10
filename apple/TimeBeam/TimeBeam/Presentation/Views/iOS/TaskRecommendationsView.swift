#if os(iOS)
import SwiftUI

struct TaskRecommendationsView: View {
    @Environment(PomodoroTimer.self) var timer
    @Environment(TaskService.self) var taskService
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
