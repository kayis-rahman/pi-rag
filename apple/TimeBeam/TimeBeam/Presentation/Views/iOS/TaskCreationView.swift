import SwiftUI

#if os(iOS)
struct TaskCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(TaskService.self) var taskService

    @State private var title = ""
    @State private var description = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Title", text: $title)
                        .autocapitalization(.words)

                    ZStack(alignment: .topLeading) {
                        if description.isEmpty {
                            Text("Description (optional)")
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        TextEditor(text: $description)
                            .frame(minHeight: 80)
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
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createTask()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
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
        }
    }

    private func createTask() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        _Concurrency.Task {
            do {
                _ = try await taskService.createTask(
                    title: trimmedTitle,
                    description: description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : description
                )
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}

#Preview {
    TaskCreationView()
        .environment(TaskService())
}
#endif