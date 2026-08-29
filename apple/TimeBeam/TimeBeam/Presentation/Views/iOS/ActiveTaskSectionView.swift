import SwiftUI

struct ActiveTaskSectionView: View {
    @Environment(PomodoroTimer.self) var timer
    @Environment(TaskService.self) var taskService

    var body: some View {
        VStack(spacing: 8) {
            Text("Active Tasks")
                .font(.caption)
                .foregroundColor(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    #if os(iOS)
                    ForEach(taskService.activeTasks.prefix(3)) { task in
                        TaskCardView(task: task, style: taskCardStyle(for: task)) {
                            timer.currentTaskId = task.id
                        } completionAction: {
                            completeTask(task)
                        }
                    }
                    #endif
                }
                .padding(.horizontal)
            }
        }
    }

    private func completeTask(_ task: UserTask) {
        _Concurrency.Task {
            do {
                _ = try await taskService.updateTask(task, status: .completed)
            } catch {
                // Handle error silently for now
                print("Failed to complete task: \(error)")
            }
        }
    }

    private func taskCardStyle(for task: UserTask) -> TaskCardStyle {
        // Generate varied styles based on task properties
        let styles: [TaskCardStyle] = [.classic, .modern, .minimal, .colorful]
        let index = abs(task.id.hashValue) % styles.count
        return styles[index]
    }
}
