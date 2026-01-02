import SwiftUI
import PomodoroTimer

// Extracted from iOSContentView.swift

    @ObservedObject var timer: PomodoroTimer

    @ObservedObject var taskService: TaskService

    @State private var recommendedTasks: [UserTask] = []



    var body: some View {

        VStack(spacing: 8) {

            Text("Recommended Tasks")

                .font(.caption)

                .foregroundColor(.secondary)



            if recommendedTasks.isEmpty {

                Text("No active tasks")

                    .font(.subheadline)

                    .foregroundColor(.secondary)

                    .padding(.horizontal)

                    .padding(.vertical, 4)

                    .background(Color.themeCardBackground.opacity(0.8))

                    .clipShape(RoundedRectangle(cornerRadius: 8))

            } else {

                ScrollView(.horizontal, showsIndicators: false) {

                    HStack(spacing: 8) {

                        ForEach(recommendedTasks.prefix(2)) { task in

                            Button {

                                timer.currentTaskId = task.id

                            } label: {

                                Text(task.title)

                                    .font(.subheadline)

                                    .foregroundColor(.themePrimary)

                                    .padding(.horizontal, 12)

                                    .padding(.vertical, 6)

                                    .background(Color.themeCardBackground.opacity(0.8))

                                    .clipShape(Capsule())

                                    .lineLimit(1)

                            }

                        }

                    }

                    .padding(.horizontal)

                }

            }

        }

        .task {

            await loadRecommendedTasks()

        }

    }



    private func loadRecommendedTasks() async {

        do {

            recommendedTasks = try await taskService.getRecommendedTasksForTimer()

        } catch {

            // Silently fail for recommendations

            recommendedTasks = []

        }

    }

}



private struct TaskCardView: View {
