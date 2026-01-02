    let task: UserTask
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var taskService: TaskService
    @EnvironmentObject var timer: PomodoroTimer

    var body: some View {
        VStack(spacing: 20) {
            // Task header
            VStack(spacing: 8) {
                Text(task.title)
                    .font(.headline)
                    .foregroundColor(.primary)

                if let description = task.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.top, 20)

            // Quick actions
            VStack(spacing: 12) {
                QuickActionButton(
                    icon: "play.circle.fill",
                    title: "Start Timer",
                    color: .themePrimary
                ) {
                    timer.currentTaskId = task.id
                    dismiss()
                }

                QuickActionButton(
                    icon: "checkmark.circle.fill",
                    title: "Mark Complete",
                    color: .green
                ) {
                    _Concurrency.Task {
                        try? await _ = taskService.updateTask(task, status: .completed)
                        dismiss()
                    }
                }

                QuickActionButton(
                    icon: "pencil",
                    title: "Edit Task",
                    color: .blue
                ) {
                    // Would navigate to edit view
                    dismiss()
                }

                QuickActionButton(
                    icon: "trash",
                    title: "Delete Task",
                    color: .red
                ) {
                    _Concurrency.Task {
                        try? await taskService.deleteTask(task)
                        dismiss()
                    }
                }
            }
            .padding(.horizontal, 20)

            Spacer()
        }
        .background(Color.themeBackground.ignoresSafeArea())
    }
}

struct QuickActionButton: View {