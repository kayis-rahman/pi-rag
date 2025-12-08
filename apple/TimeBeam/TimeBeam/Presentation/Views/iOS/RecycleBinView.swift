import SwiftUI

#if os(iOS)
struct RecycleBinView: View {
    @EnvironmentObject var taskService: TaskService
    @Environment(\.dismiss) private var dismiss
    @State private var recycleBinItems: [RecycleBinItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            ZStack {
                List {
                    Section(header: Text("Recently Deleted Tasks")) {
                        if recycleBinItems.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "trash.slash")
                                    .font(.system(size: 48))
                                    .foregroundColor(.secondary)
                                Text("Recycle bin is empty")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                Text("Deleted tasks will appear here for 30 days")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                        } else {
                            ForEach(recycleBinItems) { item in
                                RecycleBinItemRow(item: item) {
                                    restoreTask(item)
                                } permanentDeleteAction: {
                                    permanentlyDeleteTask(item)
                                }
                            }
                        }
                    }

                    if !recycleBinItems.isEmpty {
                        Section {
                            Button(role: .destructive) {
                                clearExpiredItems()
                            } label: {
                                Label("Clear Expired Items", systemImage: "trash.circle")
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)

                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                }
            }
            .navigationTitle("Recycle Bin")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadRecycleBinItems()
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

    private func loadRecycleBinItems() async {
        isLoading = true
        recycleBinItems = taskService.getRecycleBinItems()
        isLoading = false
    }

    private func restoreTask(_ item: RecycleBinItem) {
        _Concurrency.Task {
            do {
                try await taskService.restoreTask(from: item)
                await loadRecycleBinItems() // Refresh the list
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func permanentlyDeleteTask(_ item: RecycleBinItem) {
        // Remove from recycle bin (permanent deletion)
        taskService.permanentlyDeleteExpiredItems()
        _Concurrency.Task {
            await loadRecycleBinItems()
        }
    }

    private func clearExpiredItems() {
        taskService.permanentlyDeleteExpiredItems()
        _Concurrency.Task {
            await loadRecycleBinItems()
        }
    }
}

private struct RecycleBinItemRow: View {
    let item: RecycleBinItem
    let restoreAction: () -> Void
    let permanentDeleteAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.task.title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                Text("\(item.daysUntilExpiration) days left")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let description = item.task.description, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            HStack(spacing: 8) {
                Text(item.task.status.displayName)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(statusColor.opacity(0.2))
                    .foregroundColor(statusColor)
                    .clipShape(Capsule())

                Text("Deleted \(item.deletedAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Button {
                    restoreAction()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .foregroundColor(.blue)
                        .font(.caption)
                }

                Button {
                    permanentDeleteAction()
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var statusColor: Color {
        switch item.task.status {
        case .todo: return .orange
        case .inProgress: return .blue
        case .completed: return .green
        }
    }
}

#Preview {
    RecycleBinView()
        .environmentObject(TaskService())
}
#endif