import SwiftUI

#if os(iOS)
struct TaskDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var taskService: TaskService

    let task: UserTask

    @State private var title: String
    @State private var description: String
    @State private var selectedStatus: UserTask.Status
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingDeleteConfirmation = false

    init(task: UserTask) {
        self.task = task
        _title = State(initialValue: task.title)
        _description = State(initialValue: task.description ?? "")
        _selectedStatus = State(initialValue: task.status)
    }

    var body: some View {
        Form {
            Section(header: Text("Task Details")) {
                TextField("Title", text: $title)
                    .autocapitalization(.words)

                ZStack(alignment: .topLeading) {
                    if description.isEmpty {
                        Text("Description")
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                            .padding(.leading, 4)
                    }
                    TextEditor(text: $description)
                        .frame(minHeight: 80)
                }
            }

            Section(header: Text("Status")) {
                Picker("Status", selection: $selectedStatus) {
                    ForEach([UserTask.Status.todo, .inProgress, .completed], id: \.rawValue) { status in
                        Text(status.displayName)
                            .tag(status)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section(header: Text("Timestamps")) {
                LabeledContent("Created", value: task.createdAt.formatted(date: .abbreviated, time: .shortened))
                LabeledContent("Updated", value: task.updatedAt.formatted(date: .abbreviated, time: .shortened))
            }

            Section(header: Text("Session History")) {
                TaskSessionHistoryView(task: task)
            }

            Section {
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    HStack {
                        Spacer()
                        Text("Delete Task")
                        Spacer()
                    }
                }
            }

            if let errorMessage = errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
        }
        .navigationTitle("Task Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveChanges()
                }
                .disabled(!hasChanges || isLoading)
            }
        }
        .disabled(isLoading)
        .overlay {
            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.1))
            }
        }
        .confirmationDialog("Delete Task", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                deleteTask()
            }
        } message: {
            Text("Are you sure you want to delete this task? This action cannot be undone.")
        }
    }

    private var hasChanges: Bool {
        title != task.title ||
        description != (task.description ?? "") ||
        selectedStatus != task.status
    }

    private func saveChanges() {
        isLoading = true
        errorMessage = nil

        _Concurrency.Task {
            do {
                _ = try await taskService.updateTask(
                    task,
                    title: title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : title,
                    description: description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : description,
                    status: selectedStatus.apiStatus
                )
                dismiss()
            } catch {
                errorMessage = "Failed to save changes. Please try again."
                isLoading = false
            }
        }
    }

    private func deleteTask() {
        isLoading = true
        errorMessage = nil

        _Concurrency.Task {
            do {
                try await taskService.deleteTask(task)
                dismiss()
            } catch {
                errorMessage = "Failed to delete task. Please try again."
                isLoading = false
            }
        }
    }
}

private struct TaskSessionHistoryView: View {
    let task: UserTask
    @State private var sessions: [SessionRecord] = []
    @State private var isLoading = false

    var body: some View {
        if isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        } else if sessions.isEmpty {
            Text("No sessions recorded for this task")
                .foregroundColor(.secondary)
                .font(.caption)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        } else {
            VStack(spacing: 8) {
                ForEach(sessions.prefix(5)) { session in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(session.kind.displayName)
                                .font(.subheadline)
                                .foregroundColor(session.kind == .work ? .blue : .green)

                            Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Text("\(session.duration) min")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                if sessions.count > 5 {
                    Text("And \(sessions.count - 5) more sessions...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .task {
                await loadSessions()
            }
        }
    }

    private func loadSessions() async {
        isLoading = true
        defer { isLoading = false }

        // This would fetch sessions for the task from the backend
        // For now, create mock data
        try? await _Concurrency.Task.sleep(for: .seconds(0.5)) // Simulate network delay

        // Mock session data
        sessions = [
            SessionRecord(
                id: UUID(),
                startedAt: Date().addingTimeInterval(-86400),
                duration: 25,
                kind: .work
            ),
            SessionRecord(
                id: UUID(),
                startedAt: Date().addingTimeInterval(-86400 + 1800),
                duration: 5,
                kind: .shortBreak
            ),
            SessionRecord(
                id: UUID(),
                startedAt: Date().addingTimeInterval(-43200),
                duration: 25,
                kind: .work
            )
        ]
    }
}

private extension UserTask.Status {
    var apiStatus: ApiTaskStatus {
        switch self {
        case .todo: return .todo
        case .inProgress: return .inProgress
        case .completed: return .completed
        }
    }
}

#Preview {
    NavigationView {
        TaskDetailView(task: UserTask(
            userId: UUID(),
            title: "Sample Task",
            description: "This is a sample task description",
            status: .inProgress,
            createdAt: Date().addingTimeInterval(-86400),
            updatedAt: Date()
        ))
    }
    .environmentObject(TaskService())
}
#endif
