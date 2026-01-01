import AuthenticationServices

import AVFoundation
import SwiftUI
import UserNotifications

#if os(iOS)
struct iOSContentView: View {
    @EnvironmentObject var timer: PomodoroTimer
    @EnvironmentObject var logger: SessionLogger
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var taskService: TaskService
    @State private var audioPlayer: AVAudioPlayer?
    @State private var lastPhase: Phase = .work
    @State private var didRequestNotificationPermission: Bool = UserDefaults.standard.bool(forKey: "didRequestNotificationPermission")
    @State private var showingTaskPicker = false

    var body: some View {
        let ringSize: CGFloat = 280
        let ringLineWidth = max(10, ringSize * 0.065)

        ZStack {
            // Background
            Color.themeBackground.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Timer display
                CircularTimerView(size: ringSize, showSessionProgress: false)


                // Session progress indicator
                CycleProgressView(
                    completed: timer.shortBreaksCompleted,
                    total: timer.cycleSize
                )
                .frame(width: ringSize * 0.5)

                // Task selection and quick actions
                VStack(spacing: 12) {
                    // Current task or task selection
                    if let currentTaskId = timer.currentTaskId,
                       let currentTask = taskService.tasks.first(where: { $0.id == currentTaskId }) {
                        VStack(spacing: 8) {
                            Text("Working on:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(currentTask.title)
                                .font(.headline)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color.themeCardBackground.opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .frame(maxWidth: ringSize * 0.8)
                    } else {
                        // Show Active Task Section when tasks exist, otherwise show "No Task" placeholder
                        if taskService.activeTasks.isEmpty {
                            // No Task placeholder with Clear option
                            VStack(spacing: 12) {
                                Image(systemName: "checklist")
                                    .font(.system(size: 32))
                                    .foregroundColor(.secondary)
                                Text("No Task")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Button {
                                    // Clear selection (already no task selected)
                                    timer.currentTaskId = nil
                                } label: {
                                    Text("Clear")
                                        .font(.caption)
                                        .foregroundColor(.themePrimary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.themeCardBackground.opacity(0.8))
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(.vertical, 8)
                        } else {
                            // Show Active Task Section
                            ActiveTaskSectionView(timer: timer, taskService: taskService)
                        }
                    }

                    // Task selection button
                    Button {
                        showingTaskPicker = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "checklist")
                            Text(timer.currentTaskId == nil ? "Select Task" : "Change Task")
                        }
                        .font(.subheadline)
                        .foregroundColor(.themePrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.themeCardBackground.opacity(0.8))
                        .clipShape(Capsule())
                    }
                }

                // Primary action button
                PrimaryButton(
                    title: timer.isRunning ? "Pause" : "Start",
                    icon: timer.isRunning ? "pause.fill" : "play.fill",
                    action: {
                        if timer.isRunning {
                            TimerSyncManager.shared.syncTimerAction(.pause)
                        } else {
                            startWithPermission()  // Will also be updated to use TimerSyncManager
                        }
                    }
                )
                .frame(width: 200)

                Spacer()
            }
            .padding(.horizontal, 24)

            // Controls in top corner
            VStack {
                HStack {
                    Spacer()

                    // Reset button (top right)
                    Button(action: { 
                        TimerSyncManager.shared.syncTimerAction(.reset)
                    }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(Color.themeTextSecondary)
                            .frame(width: 44, height: 44)
                            .background(Color.themeCardBackground.opacity(0.8))
                            .clipShape(Circle())
                    }
                    .padding([.top, .trailing], 20)
                }
                Spacer()
            }
        }
        .onAppear {
            lastPhase = timer.phase
        }
        .onChange(of: timer.phase) { oldPhase, newPhase in
            if newPhase != oldPhase {
                playChime()
                lastPhase = newPhase
            }
        }
        .sheet(isPresented: $showingTaskPicker) {
            TaskPickerView { selectedTask in
                timer.currentTaskId = selectedTask?.id
            }
        }
    }

    private func startWithPermission() {
        if !didRequestNotificationPermission {
            NotificationManager.shared.requestPermission { _ in }
            didRequestNotificationPermission = true
            UserDefaults.standard.set(true, forKey: "didRequestNotificationPermission")
        }
        TimerSyncManager.shared.syncTimerAction(.start)
    }

    private func playChime() {
        guard let soundURL = Bundle.main.url(forResource: "chime-sound", withExtension: "mp3") else { return }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.play()
        } catch {
            // ignore
        }
    }
}

// MARK: - Helper Views

private struct ActiveTaskSectionView: View {
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
    let task: UserTask
    let style: TaskCardStyle
    let selectionAction: () -> Void
    let completionAction: () -> Void

    @State private var isCompleted = false
    @State private var showUndoButton = false

    var body: some View {
        Button(action: selectionAction) {
            VStack(spacing: 8) {
                // Header with checkbox and title
                HStack(spacing: 8) {
                    Button {
                        withAnimation(.spring()) {
                            isCompleted.toggle()
                            if isCompleted {
                                completionAction()
                                showUndoButton = true
                                // Auto-hide undo button after 3 seconds
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    withAnimation {
                                        showUndoButton = false
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(isCompleted ? .green : .secondary)
                            .font(.system(size: 16))
                    }

                    Text(task.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Spacer()
                }

                if let description = task.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Undo button
                if showUndoButton {
                    Button("Undo") {
                        withAnimation {
                            isCompleted = false
                            showUndoButton = false
                            undoCompletion()
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.themePrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.themeCardBackground.opacity(0.8))
                    .clipShape(Capsule())
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(12)
            .frame(width: 160, height: style.height)
            .background(style.background)
            .clipShape(style.shape)
            .overlay(
                style.border
            )
            .shadow(color: style.shadowColor, radius: style.shadowRadius, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    if value.translation.width < -50 {
                        // Right swipe to complete
                        withAnimation(.spring()) {
                            isCompleted = true
                            completionAction()
                            showUndoButton = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                withAnimation {
                                    showUndoButton = false
                                }
                            }
                        }
                    }
                }
        )
    }

    private func undoCompletion() {
        // This would call TaskService.undoTaskCompletion
        // For now, just reset the local state
        print("Undo completion for task: \(task.title)")
    }
}

enum TaskCardStyle {
    case classic, modern, minimal, colorful

    var height: CGFloat {
        switch self {
        case .classic: return 100
        case .modern: return 120
        case .minimal: return 80
        case .colorful: return 110
        }
    }

    var background: some View {
        Group {
            switch self {
            case .classic:
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.themeCardBackground.opacity(0.9))
            case .modern:
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.themeCardBackground.opacity(0.95))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.themePrimary.opacity(0.3), lineWidth: 1)
                    )
            case .minimal:
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.themeCardBackground.opacity(0.7))
            case .colorful:
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [Color.themePrimary.opacity(0.2), Color.themeSecondary.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        }
    }

    var shape: some Shape {
        switch self {
        case .classic: return RoundedRectangle(cornerRadius: 12)
        case .modern: return RoundedRectangle(cornerRadius: 16)
        case .minimal: return RoundedRectangle(cornerRadius: 8)
        case .colorful: return RoundedRectangle(cornerRadius: 20)
        }
    }

    var border: some View {
        Group {
            switch self {
            case .classic, .minimal:
                EmptyView()
            case .modern:
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.themePrimary.opacity(0.3), lineWidth: 1)
            case .colorful:
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.themePrimary.opacity(0.5), lineWidth: 1)
            }
        }
    }

    var shadowColor: Color {
        switch self {
        case .classic: return Color.black.opacity(0.1)
        case .modern: return Color.themePrimary.opacity(0.2)
        case .minimal: return Color.black.opacity(0.05)
        case .colorful: return Color.themePrimary.opacity(0.3)
        }
    }

    var shadowRadius: CGFloat {
        switch self {
        case .classic: return 4
        case .modern: return 6
        case .minimal: return 2
        case .colorful: return 8
        }
    }
}

private struct CycleProgressView: View {
    let completed: Int
    let total: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<total, id: \.self) { index in
                Circle()
                    .fill(index < completed ? Color.themePrimary : Color.themeTextSecondary.opacity(0.3))
                    .frame(width: 10, height: 10)
            }
        }
    }
}

#Preview {
    iOSContentView()
        .environmentObject(PomodoroTimer())
        .environmentObject(SessionLogger())
        .environmentObject(AuthManager())
        .environmentObject(TaskService())
}
#endif
