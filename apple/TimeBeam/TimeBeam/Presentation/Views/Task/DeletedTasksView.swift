#if os(iOS)
import SwiftUI

struct DeletedTasksView: View {
    @Environment(TaskService.self) var taskService
    @Environment(\.dismiss) private var dismiss
    @State private var showingPermanentDeleteAlert = false
    @State private var taskToDelete: RecycleBinItem?

    var body: some View {
        NavigationView {
            ZStack {
                Color.themeBackground
                    .ignoresSafeArea()

                if taskService.getRecycleBinItems().isEmpty {
                    VStack(spacing: 24) {
                        Spacer()

                        ZStack {
                            Circle()
                                .fill(Color.themePrimary.opacity(0.1))
                                .frame(width: 120, height: 120)

                            Image(systemName: "trash.circle")
                                .font(.system(size: 48))
                                .foregroundColor(.themePrimary)
                        }

                        VStack(spacing: 8) {
                            Text("Recycle Bin is Empty")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)

                            Text("Deleted tasks will appear here for 30 days")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 20)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(taskService.getRecycleBinItems()) { item in
                                DeletedTaskRow(item: item, onRestore: {
                                    restoreTask(item)
                                }, onDelete: {
                                    taskToDelete = item
                                    showingPermanentDeleteAlert = true
                                })
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
            .navigationTitle("Recycle Bin")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .alert("Permanently Delete Task?", isPresented: $showingPermanentDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete Forever", role: .destructive) {
                    if let item = taskToDelete {
                        permanentlyDeleteTask(item)
                    }
                }
            } message: {
                if let item = taskToDelete {
                    Text("This action cannot be undone. The task '\(item.task.title)' will be permanently deleted.")
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    private func restoreTask(_ item: RecycleBinItem) {
        _Concurrency.Task {
            do {
                try await taskService.restoreTask(from: item)
            } catch {
                AppLogger.error("Failed to restore task: \(error.localizedDescription)", category: .general)
            }
        }
    }

    private func permanentlyDeleteTask(_ item: RecycleBinItem) {
        // For now, just remove from recycle bin (in a real app, this would delete from backend too)
        taskService.removeFromRecycleBin(item)
    }
}
#endif
