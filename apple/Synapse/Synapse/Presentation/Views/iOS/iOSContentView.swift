import AuthenticationServices

import AVFoundation
import SwiftUI
import UserNotifications

#if os(iOS)
struct iOSContentView: View {
    @Environment(PomodoroTimer.self) var timer
    @Environment(SessionLogger.self) var logger
    @Environment(AuthManager.self) var authManager
    @Environment(TaskService.self) var taskService
    @State private var audioPlayer: AVAudioPlayer?
    @State private var lastPhase: Phase = .work
    @State private var didRequestNotificationPermission: Bool = UserDefaults.standard.bool(forKey: "didRequestNotificationPermission")
    @State private var showingTaskPicker = false

    var body: some View {
        let ringSize: CGFloat = 250

        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                focusHeader

                VStack(spacing: 12) {
                    CircularTimerView(size: ringSize, showSessionProgress: false)
                    CycleProgressView(timer: timer)
                }
                .frame(maxWidth: .infinity)

                activeTaskCard

                if !upNextTasks.isEmpty {
                    upNextSection
                }

                PrimaryButton(
                    title: FocusTabBehavior.actionTitle(
                        isRunning: timer.isRunning,
                        remainingSeconds: timer.remainingSeconds,
                        currentDuration: timer.currentDuration
                    ),
                    icon: timer.isRunning ? "pause.fill" : "play.fill",
                    action: {
                        if timer.isRunning {
                            Task { await TimerSyncManager.shared.syncTimerAction(.pause) }
                        } else {
                            startWithPermission()
                        }
                    }
                )
                .accessibilityIdentifier("focus-primary-action")

                focusStats
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 24)
        }
        .background(phaseBackground.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingTaskPicker = true
                    } label: {
                        Label(timer.currentTaskId == nil ? "Select task" : "Change task", systemImage: "checklist")
                    }
                    Button {
                        Task { await TimerSyncManager.shared.syncTimerAction(.reset) }
                    } label: {
                        Label("Reset timer", systemImage: "arrow.counterclockwise")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("Focus options")
            }
        }
        .onAppear {
            TimerSyncManager.shared.configure(with: timer)
            lastPhase = timer.phase
            if UserDefaults.standard.bool(forKey: "synapse.pendingStartFocus") {
                UserDefaults.standard.removeObject(forKey: "synapse.pendingStartFocus")
                startWithPermission()
            }
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
        guard UserDefaults.standard.bool(forKey: "soundEnabled") else { return }
        guard let soundURL = Bundle.main.url(forResource: "chime-sound", withExtension: "mp3") else { return }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.play()
        } catch {
            // ignore
        }
    }

    private var focusHeader: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(FocusTabBehavior.heading(for: timer.phase))
                .font(.system(size: 25, weight: .bold, design: .rounded))
                .tracking(-0.45)
            Text(FocusTabBehavior.prompt(
                for: timer.phase,
                isRunning: timer.isRunning,
                remainingSeconds: timer.remainingSeconds,
                currentDuration: timer.currentDuration
            ))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var activeTaskCard: some View {
        Button { showingTaskPicker = true } label: {
            HStack(spacing: 13) {
                Image(systemName: timer.currentTaskId == nil ? "scope" : "checkmark.circle.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(timer.currentTaskId == nil ? Color.themePrimary : Color.themeAccent)
                    .frame(width: 42, height: 42)
                    .background(Color.themePrimary.opacity(0.14), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(timer.currentTaskId == nil ? "No task selected" : "Working on")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(currentTask?.title ?? "Choose a task to make this session count")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
            .padding(15)
            .background(Color.themeCardBackground.opacity(0.82), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.themePrimary.opacity(0.14), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("focus-current-task")
    }

    private var upNextSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Up next")
                    .font(.subheadline.weight(.bold))
                Spacer()
                Text("\(upNextTasks.count) tasks")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(upNextTasks) { task in
                        Button {
                            timer.currentTaskId = task.id
                        } label: {
                            Text(task.title)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                                .padding(.horizontal, 13)
                                .padding(.vertical, 10)
                                .background(Color.themeCardBackground.opacity(0.7), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var focusStats: some View {
        HStack(spacing: 10) {
            FocusStat(value: formattedFocusTime, label: "Today")
            FocusStat(value: "\(todaySessionCount)", label: todaySessionCount == 1 ? "Session" : "Sessions")
            FocusStat(value: "\(timer.shortBreaksCompleted + 1)/\(timer.cycleSize)", label: "Cycle")
        }
    }

    private var currentTask: UserTask? {
        guard let currentTaskId = timer.currentTaskId else { return nil }
        return taskService.tasks.first { $0.id == currentTaskId }
    }

    private var upNextTasks: [UserTask] {
        FocusTabBehavior.upNextTasks(from: taskService.activeTasks, excluding: timer.currentTaskId)
    }

    private var todayProductiveRecords: [SessionRecordDto] {
        logger.records.filter { Calendar.current.isDateInToday($0.startedAt) && $0.isProductive }
    }

    private var todaySessionCount: Int { todayProductiveRecords.count }

    private var formattedFocusTime: String {
        FocusTabBehavior.formattedFocusTime(seconds: todayProductiveRecords.reduce(0) { $0 + $1.durationSeconds })
    }

    private var phaseBackground: some View {
        ZStack {
            Color.themeBackground
            RadialGradient(
                colors: [phaseTint.opacity(timer.isRunning ? 0.18 : 0.08), .clear],
                center: .top,
                startRadius: 20,
                endRadius: 430
            )
        }
    }

    private var phaseTint: Color {
        switch timer.phase {
        case .work: return .themePrimary
        case .break, .longBreak: return .themeOrangePrimary
        }
    }
}

private struct FocusStat: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.subheadline.weight(.bold).monospacedDigit())
                .foregroundStyle(.primary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .background(Color.themeCardBackground.opacity(0.58), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
    }
}

#endif
