    let tasks: [UserTask]
    @Binding var selectedTaskForAction: UserTask?
    @Binding var showingQuickActions: Bool

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(tasks) { task in
                    EnhancedTaskRow(task: task)
                        .onTapGesture {
                            selectedTaskForAction = task
                        }
                        .onLongPressGesture {
                            showingQuickActions = true
                        }
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale(scale: 0.8).combined(with: .opacity)
                        ))
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
        }
    }
}

struct EnhancedTaskRow: View {
    let task: UserTask
    @EnvironmentObject var taskService: TaskService
    @State private var isCompleting = false

    var body: some View {
        HStack(spacing: 16) {
            // Completion indicator with Liquid Glass design
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.2))
                    .frame(width: 32, height: 32)

                if task.status == .completed {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(statusColor)
                } else {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .strikethrough(task.status == .completed)

                if let description = task.description, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .strikethrough(task.status == .completed)
                }

                HStack(spacing: 8) {
                    Text(task.status.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor.opacity(0.1))
                        .foregroundColor(statusColor)
                        .clipShape(Capsule())

                    Text(task.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Action indicator
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.secondary.opacity(0.5))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.themeCardBackground.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.themePrimary.opacity(0.05), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .scaleEffect(isCompleting ? 0.95 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isCompleting)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            // Right swipe: Done & Delete
            Button {
                performDoneAndDelete()
            } label: {
                Label("Done & Delete", systemImage: "checkmark.circle.fill")
            }
            .tint(.green)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            // Left swipe: Undo (if task was recently completed)
            if task.status == .completed {
                Button {
                    performUndo()
                } label: {
                    Label("Undo", systemImage: "arrow.uturn.backward.circle.fill")
                }
                .tint(.blue)
            }
        }
    }

    private func performDoneAndDelete() {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
            isCompleting = true
        }

                    _Concurrency.Task {
            do {
                // First mark as completed, then soft delete
                _ = try await taskService.updateTask(task, status: .completed)
                try await taskService.softDeleteTask(task)
            } catch {
                AppLogger.error("Failed to complete and delete task: \(error.localizedDescription)", category: .general)
            }

            await MainActor.run {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                    isCompleting = false
                }
            }
        }
    }

    private func performUndo() {
                    _Concurrency.Task {
            do {
                try await taskService.undoTaskCompletion(task)
            } catch {
                AppLogger.error("Failed to undo task completion: \(error.localizedDescription)", category: .general)
            }
        }
    }

    private var statusColor: Color {
        switch task.status {
        case .todo: return .orange
        case .inProgress: return .blue
        case .completed: return .green
        }
    }
}


struct TaskQuickActionsSheet: View {