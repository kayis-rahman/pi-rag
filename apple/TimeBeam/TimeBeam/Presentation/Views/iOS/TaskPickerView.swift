import SwiftUI

#if os(iOS)
struct TaskPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var taskService: TaskService

    let onTaskSelected: (UserTask?) -> Void

    @State private var searchText = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var filteredTasks: [UserTask] {
        if searchText.isEmpty {
            return taskService.activeTasks
        } else {
            return taskService.activeTasks.filter { task in
                task.title.localizedCaseInsensitiveContains(searchText) ||
                (task.description?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                List {
                    Section(header: Text("Active Tasks")) {
                        Button {
                            onTaskSelected(nil)
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "xmark.circle")
                                    .foregroundColor(.secondary)
                                Text("No Task")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("Clear selection")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        ForEach(filteredTasks) { task in
                            Button {
                                onTaskSelected(task)
                                dismiss()
                            } label: {
                                TaskRowView(task: task)
                                    .foregroundColor(.primary)
                            }
                        }
                    }

                    if filteredTasks.isEmpty && !searchText.isEmpty {
                        Section {
                            Text("No tasks match your search")
                                .foregroundColor(.secondary)
                                .italic()
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .searchable(text: $searchText, prompt: "Search tasks")

                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                }
            }
            .navigationTitle("Select Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadActiveTasks()
            }
            .refreshable {
                await loadActiveTasks()
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }

    private func loadActiveTasks() async {
        isLoading = true
        errorMessage = nil

        do {
            try await taskService.fetchActiveTasks()
        } catch {
            // Only show error if there are no cached tasks available
            if taskService.activeTasks.isEmpty {
                errorMessage = error.localizedDescription
            }
        }

        isLoading = false
    }
}

private struct TaskRowView: View {
    let task: UserTask

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(task.title)
                .font(.headline)

            if let description = task.description, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            HStack(spacing: 8) {
                Text(task.status.displayName)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(statusColor.opacity(0.2))
                    .foregroundColor(statusColor)
                    .clipShape(Capsule())

                Text(task.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var statusColor: Color {
        switch task.status {
        case .todo: return .orange
        case .inProgress: return .blue
        case .completed: return .green
        }
    }
}

#Preview {
    TaskPickerView { task in
        print("Selected task: \(task?.title ?? "None")")
    }
    .environmentObject(TaskService())
}
#endif