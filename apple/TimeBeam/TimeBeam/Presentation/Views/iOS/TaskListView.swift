import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

#if os(iOS)
struct TaskListView: View {
    @Environment(TaskService.self) var taskService
    @State private var showingCreateTask = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var searchText = ""
    @State private var selectedStatusFilter: UserTask.Status? = nil
    @State private var showingFilters = false

    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    // Search and Filter Bar
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField("Search tasks...", text: $searchText)
                                .textFieldStyle(.plain)

                            if !searchText.isEmpty {
                                Button {
                                    searchText = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.horizontal)

                        // Status Filter Pills
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                FilterPill(title: "All", isSelected: selectedStatusFilter == nil) {
                                    selectedStatusFilter = nil
                                }

                                ForEach([UserTask.Status.todo, .inProgress, .completed], id: \.self) { status in
                                    FilterPill(title: status.displayName, isSelected: selectedStatusFilter == status) {
                                        selectedStatusFilter = status
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 8)
                    .background(Color(.systemBackground))

                    List {
                        ForEach(filteredTasks) { task in
                        TaskRowView(task: task)
                            .swipeActions(edge: .trailing) {
                                if task.isActive {
                                    Button(role: .destructive) {
                                        completeTask(task)
                                    } label: {
                                        Label("Complete", systemImage: "checkmark.circle")
                                    }
                                    .tint(.green)
                                }

                                Button(role: .destructive) {
                                    deleteTask(task)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    await refreshTasks()
                }

                if taskService.tasks.isEmpty && !isLoading {
                    VStack(spacing: 16) {
                        Image(systemName: "checklist")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No tasks yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Create your first task to get started")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }

                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                }
            }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showingCreateTask = true
                        } label: {
                            Label("New Task", systemImage: "plus")
                        }

                        NavigationLink(destination: TaskAnalyticsView()) {
                            Label("Analytics", systemImage: "chart.bar")
                        }

                        NavigationLink(destination: RecycleBinView()) {
                            Label("Recycle Bin", systemImage: "trash")
                        }

                        Button {
                            exportTasks()
                        } label: {
                            Label("Export", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingCreateTask) {
                TaskCreationView()
            }
            .task {
                await loadTasks()
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
    }

    private func loadTasks() async {
        isLoading = true
        errorMessage = nil

        do {
            try await taskService.fetchTasks(status: selectedStatusFilter.flatMap { ApiTaskStatus(rawValue: $0.rawValue) })
        } catch {
            // Only show error if there are no cached tasks available
            if taskService.tasks.isEmpty {
                errorMessage = error.localizedDescription
            }
        }

        isLoading = false
    }

    private func refreshTasks() async {
        do {
            try await taskService.fetchTasks(status: selectedStatusFilter.flatMap { ApiTaskStatus(rawValue: $0.rawValue) })
        } catch {
            // For refresh operations, show error even if tasks exist, but make it less intrusive
            errorMessage = error.localizedDescription
        }
    }

    private func completeTask(_ task: UserTask) {
        _Concurrency.Task {
            do {
                _ = try await taskService.updateTask(task, status: .completed)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func deleteTask(_ task: UserTask) {
        _Concurrency.Task {
            do {
                try await taskService.softDeleteTask(task)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func exportTasks() {
        let tasksToExport = filteredTasks.isEmpty ? taskService.tasks : filteredTasks

        do {
            let exportData = try createExportData(for: tasksToExport)
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("tasks_export.json")

            try exportData.write(to: tempURL, atomically: true, encoding: .utf8)

            // Share the file
            let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)

            // Present the share sheet
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootVC = window.rootViewController {
                rootVC.present(activityVC, animated: true)
            }
        } catch {
            errorMessage = "Failed to export tasks."
        }
    }

    private func createExportData(for tasks: [UserTask]) throws -> String {
        let exportTasks = tasks.map { task in
            [
                "id": task.id.uuidString,
                "title": task.title,
                "description": task.description ?? "",
                "status": task.status.rawValue,
                "createdAt": ISO8601DateFormatter().string(from: task.createdAt),
                "updatedAt": ISO8601DateFormatter().string(from: task.updatedAt)
            ]
        }

        let exportDict: [String: Any] = [
            "exportDate": ISO8601DateFormatter().string(from: Date()),
            "totalTasks": tasks.count,
            "tasks": exportTasks
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: exportDict, options: .prettyPrinted)
        return String(data: jsonData, encoding: .utf8) ?? "{}"
    }
}

private struct TaskRowView: View {
    let task: UserTask
    @State private var progress: TaskProgress?
    @State private var isLoadingProgress = false
    @State private var isCompleted = false
    @State private var showUndoButton = false

    var body: some View {
        HStack {
            // Checkbox for completion
            Button {
                toggleCompletion()
            } label: {
                Image(systemName: isCompleted || task.status == .completed ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isCompleted || task.status == .completed ? .green : .secondary)
                    .font(.system(size: 20))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(task.title)
                        .font(.headline)
                        .strikethrough(task.status == .completed || isCompleted)

                    Spacer()

                    // Quick action button for active tasks
                    if task.status == .inProgress && !isCompleted {
                        Button {
                            startTimerWithTask()
                        } label: {
                            Image(systemName: "play.circle")
                                .foregroundColor(.blue)
                                .font(.title3)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if let description = task.description, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .strikethrough(task.status == .completed || isCompleted)
                }

                // Progress information
                if let progress = progress, task.status == .inProgress && !isCompleted {
                    HStack(spacing: 8) {
                        ProgressView(value: progress.progressPercentage)
                            .progressViewStyle(.linear)
                            .frame(width: 60, height: 4)
                            .tint(.blue)

                        Text("\(progress.completedSessions)/\(progress.totalEstimatedSessions) sessions")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(progress.formattedTimeSpent)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                HStack(spacing: 8) {
                    Text(task.status.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(statusColor.opacity(0.2))
                        .foregroundColor(statusColor)
                        .clipShape(Capsule())

                    Text(task.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if task.status == .completed || isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }

                // Undo button
                if showUndoButton {
                    Button("Undo Completion") {
                        undoCompletion()
                    }
                    .font(.caption)
                    .foregroundColor(.themePrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Capsule())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.opacity)
                }
            }
        }
        .padding(.vertical, 8)
        .task {
            await loadProgress()
            isCompleted = task.status == .completed
        }
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    if value.translation.width < -50 && task.status != .completed {
                        // Right swipe to complete
                        toggleCompletion()
                    }
                }
        )
    }

    private func toggleCompletion() {
        withAnimation(.spring()) {
            isCompleted.toggle()
            if isCompleted {
                // Mark as completed
                completeTask()
                showUndoButton = true
                // Auto-hide undo button after 5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    withAnimation {
                        showUndoButton = false
                    }
                }
            } else {
                // Undo completion
                undoCompletion()
            }
        }
    }

    private func completeTask() {
        // This would call TaskService.updateTask with completed status
        // For now, just update local state
        print("Marking task as completed: \(task.title)")
    }

    private func undoCompletion() {
        withAnimation {
            isCompleted = false
            showUndoButton = false
            // This would call TaskService.undoTaskCompletion
            print("Undoing completion for task: \(task.title)")
        }
    }

    private func loadProgress() async {
        guard task.status == .inProgress else { return }

        isLoadingProgress = true
        defer { isLoadingProgress = false }

        // Get task service from environment
        // This would need to be injected properly in a real implementation
        do {
            let taskService = TaskService() // This is not ideal - should be injected
            progress = try await taskService.getTaskProgress(task)
        } catch {
            // Silently fail for progress loading
            print("Failed to load task progress: \(error)")
        }
    }

    private func startTimerWithTask() {
        // This would integrate with the PomodoroTimer
        // For now, just show that the action was triggered
        print("Starting timer with task: \(task.title)")
    }

    private var statusColor: Color {
        switch task.status {
        case .todo: return .orange
        case .inProgress: return .blue
        case .completed: return .green
        }
    }
}

// MARK: - Computed Properties

extension TaskListView {
    private var filteredTasks: [UserTask] {
        taskService.tasks.filter { task in
            // Status filter
            if let statusFilter = selectedStatusFilter {
                guard task.status.rawValue == statusFilter.rawValue else { return false }
            }

            // Search filter
            if !searchText.isEmpty {
                let searchLower = searchText.lowercased()
                let titleMatch = task.title.lowercased().contains(searchLower)
                let descriptionMatch = task.description?.lowercased().contains(searchLower) ?? false
                guard titleMatch || descriptionMatch else { return false }
            }

            return true
        }
    }
}

// MARK: - Supporting Components

private struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue.opacity(0.2) : Color(.secondarySystemBackground))
                .foregroundColor(isSelected ? .blue : .primary)
                .clipShape(Capsule())
        }
    }
}

#Preview {
    TaskListView()
        .environment(TaskService())
}
#endif