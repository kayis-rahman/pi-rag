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
                            Task {
                                await TimerSyncManager.shared.syncTimerAction(.pause)
                            }
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
                        Task {
                            await TimerSyncManager.shared.syncTimerAction(.reset)
                        }
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
        Task {
            await TimerSyncManager.shared.syncTimerAction(.start)
        }
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
