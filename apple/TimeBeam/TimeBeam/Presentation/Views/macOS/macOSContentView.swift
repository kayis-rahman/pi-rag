import AVFoundation
import SwiftUI
import UserNotifications

#if os(macOS)
import AppKit

struct macOSContentView: View {
    @EnvironmentObject var timer: PomodoroTimer
    @EnvironmentObject var logger: SessionLogger
    @EnvironmentObject var authManager: AuthManager
    @State private var audioPlayer: AVAudioPlayer?
    @State private var lastPhase: Phase = .work
    @State private var didRequestNotificationPermission: Bool = UserDefaults.standard.bool(forKey: "didRequestNotificationPermission")
    @State private var showingAnalytics: Bool = false
    @State private var showingAbout: Bool = false

    var body: some View {
        let ringSize: CGFloat = 280
        let ringLineWidth = max(10, ringSize * 0.065)
        let buttonSize: CGFloat = 54

        return VStack(spacing: 10) {
            timerRing(ringSize: ringSize, ringLineWidth: ringLineWidth, buttonSize: buttonSize)

            HStack {
                resetButton(buttonSize: buttonSize)
                Spacer()
                optionsControl(buttonSize: buttonSize)
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 20)
        .frame(width: ringSize + 60)
        .background(Color.themeBackground.ignoresSafeArea())
        .onAppear {
            lastPhase = timer.phase
        }
        .onChange(of: timer.phase) { oldPhase, newPhase in
            if newPhase != oldPhase {
                playChime()
                lastPhase = newPhase
            }
        }
        .sheet(isPresented: $showingAnalytics) {
            AnalyticsView()
                .environmentObject(logger)
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
    }

    // MARK: - Bindings for macOS Menu Pickers
    private var workDurationBinding: Binding<Int> {
        Binding<Int>(
            get: { timer.workDuration / 60 },
            set: { newValue in
                updateTimerDurations(workMinutes: newValue, shortBreakMinutes: timer.breakDuration / 60, longBreakMinutes: timer.longBreakDuration / 60)
            }
        )
    }

    private var shortBreakDurationBinding: Binding<Int> {
        Binding<Int>(
            get: { timer.breakDuration / 60 },
            set: { newValue in
                updateTimerDurations(workMinutes: timer.workDuration / 60, shortBreakMinutes: newValue, longBreakMinutes: timer.longBreakDuration / 60)
            }
        )
    }

    private var longBreakDurationBinding: Binding<Int> {
        Binding<Int>(
            get: { timer.longBreakDuration / 60 },
            set: { newValue in
                updateTimerDurations(workMinutes: timer.workDuration / 60, shortBreakMinutes: timer.breakDuration / 60, longBreakMinutes: newValue)
            }
        )
    }

    private func updateTimerDurations(workMinutes: Int, shortBreakMinutes: Int, longBreakMinutes: Int) {
        let work = workMinutes * 60
        let short = shortBreakMinutes * 60
        let long = longBreakMinutes * 60

        // Keep the rest of the state unchanged, only swap the durations
        timer.applySyncedState(
            phase: timer.phase,
            remainingSeconds: min(timer.remainingSeconds, {
                switch timer.phase {
                case .work: return work
                case .break: return short
                case .longBreak: return long
                }
            }()),
            isRunning: timer.isRunning,
            workDuration: work,
            breakDuration: short,
            longBreakDuration: long,
            autoStartNextSession: timer.autoStartNextSession,
            shortBreaksCompleted: timer.shortBreaksCompleted,
            startTimestamp: timer.startTimestamp,
            pauseTimestamp: timer.pauseTimestamp,
            lastModifiedTimestamp: Date().timeIntervalSince1970
        )
    }

    private func timerRing(ringSize: CGFloat, ringLineWidth: CGFloat, buttonSize: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(Color.themeTextSecondary.opacity(0.3), lineWidth: ringLineWidth)

            Circle()
                .trim(from: 0, to: timer.progress)
                .stroke(
                    AngularGradient.forThemePhase(timer.phase),
                    style: StrokeStyle(lineWidth: ringLineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: ringSize * 0.0) {
                Text(timer.remainingSeconds.mmss)
                    .font(.system(size: ringSize * 0.22, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Color.themeTextPrimary)
                    .padding(.top, 10)

                Text(timer.phase == .work ? "just focus " : "break time!")
                    .font(.system(size: ringSize * 0.08, weight: .regular))
                    .foregroundStyle(Color.themeTextSecondary)
                    .padding(.bottom, 10)

                CycleProgressView()
                .frame(width: ringSize * 0.5)
                .padding(.bottom, 15)
                playPauseButton(buttonSize: buttonSize)
            }
        }
        .frame(width: ringSize, height: ringSize)
    }

    @ViewBuilder
    private func optionsControl(buttonSize: CGFloat) -> some View {
        let minutesRange = Array(stride(from: 5, to: 121, by: 5))
        Menu {
            Picker("Focus Duration", selection: workDurationBinding) {
                ForEach(minutesRange, id: \.self) { Text("\($0) minutes").tag($0) }
            }

            Picker("Short Break", selection: shortBreakDurationBinding) {
                ForEach(minutesRange, id: \.self) { Text("\($0) minutes").tag($0) }
            }

            Picker("Long Break", selection: longBreakDurationBinding) {
                ForEach(minutesRange, id: \.self) { Text("\($0) minutes").tag($0) }
            }

            Divider()

            Toggle("Auto-start next session", isOn: Binding(
                get: { timer.autoStartNextSession },
                set: { timer.autoStartNextSession = $0 }
            ))

            Divider()

            Button("Analytics & Insights…") {
                showingAnalytics = true
            }

            Divider()

            Button("About TimeBeam") {
                showingAbout = true
            }

            Divider()

            if authManager.isSignedIn {
                if let name = authManager.displayName, !name.isEmpty {
                    Text(name)
                }
                Button("Sign Out", role: .destructive) {
                    _Concurrency.Task { await authManager.signOut() }
                }
            } else {
                Button("Sign In with Google") {
                    _Concurrency.Task {
                        do {
                            try await authManager.signInWithGoogle()
                        } catch {
                            print("Sign-in failed: \(error)")
                        }
                    }
                }
            }

            Divider()

            Button("Reset to Defaults", role: .destructive) {
                timer.reset()
            }

        } label: {
            Image(systemName: "gearshape.fill")
                .font(.system(size: buttonSize * 0.45))
                .frame(width: buttonSize, height: buttonSize)
                .foregroundStyle(Color.themeTextSecondary)
                .background(.regularMaterial)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Options")
    }

    private func playPauseButton(buttonSize: CGFloat) -> some View {
        Button {
            if timer.isRunning {
                Task {
                    await TimerSyncManager.shared.syncTimerAction(.pause)
                }
            } else {
                startWithPermission()  // Will also be updated to use TimerSyncManager
            }
        } label: {
            Image(systemName: timer.isRunning ? "pause.fill" : "play.fill")
                .font(.system(size: buttonSize * 0.5, weight: .bold))
                .frame(width: buttonSize * 1.2, height: buttonSize * 1.2)
                .background(Color.themePrimary)
                .foregroundStyle(Color.themeAccent)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(timer.isRunning ? "Pause" : "Start")
    }

    private func resetButton(buttonSize: CGFloat) -> some View {
        Button {
            Task {
                await TimerSyncManager.shared.syncTimerAction(.reset)
            }
        } label: {
            Image(systemName: "arrow.counterclockwise")
                .font(.system(size: buttonSize * 0.45))
                .frame(width: buttonSize, height: buttonSize)
                .foregroundStyle(Color.themeTextSecondary)
                .background(.regularMaterial)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Reset")
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

#endif

#if os(macOS)
#Preview {
    macOSContentView()
        .environmentObject(PomodoroTimer())
        .environmentObject(SessionLogger())
        .environmentObject(AuthManager())
}
#endif

// All PomodoroTimer methods are now properly implemented - no shims needed

