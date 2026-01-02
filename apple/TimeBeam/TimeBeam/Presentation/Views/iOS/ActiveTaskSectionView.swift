import SwiftUI
import PomodoroTimer

// Extracted from iOSContentView.swift

    @ObservedObject var timer: PomodoroTimer

    @ObservedObject var taskService: TaskService



    var body: some View {

        VStack(spacing: 8) {

            Text("Active Tasks")

                .font(.caption)

                .foregroundColor(.secondary)



            ScrollView(.horizontal, showsIndicators: false) {

                HStack(spacing: 12) {

                    ForEach(taskService.activeTasks.prefix(3)) { task in

                        TaskCardView(task: task, style: taskCardStyle(for: task)) {

                            timer.currentTaskId = task.id

                        } completionAction: {

                            completeTask(task)

                        }

                    }

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



private struct TaskRecommendationsView: View {
