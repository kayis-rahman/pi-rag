import SwiftUI
#if os(iOS) || os(macOS)
import AVFoundation
#endif
import UserNotifications
#if os(macOS)
import AppKit
#elseif os(iOS)
import AuthenticationServices
#endif

struct ContentView: View {
    @EnvironmentObject var timer: PomodoroTimer
    @EnvironmentObject var logger: SessionLogger
    @EnvironmentObject var authManager: AuthManager
    #if os(iOS) || os(macOS)
    @State private var audioPlayer: AVAudioPlayer?
    #endif
    @State private var lastPhase: Phase = .work
    @State private var didRequestNotificationPermission: Bool = UserDefaults.standard.bool(forKey: "didRequestNotificationPermission")
    var body: some View {
        ZStack {
            // Background
            Color.themeBackground.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Timer display
                CircularTimerView(size: 350, showSessionProgress: false)

                // Session progress indicator
                CycleProgressView(
                    completed: timer.shortBreaksCompleted,
                    total: timer.cycleSize
                )
                .frame(width: 350 * 0.5)

                // Primary action button
                PrimaryButton(
                    title: timer.isRunning ? "Pause" : "Start",
                    icon: timer.isRunning ? "pause.fill" : "play.fill",
                    action: {
                        if timer.isRunning {
                            timer.pause()
                        } else {
                            startWithPermission()
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
                    Button(action: { timer.reset() }) {
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
    }
    
    // MARK: - Bindings for macOS Menu Pickers
    #if os(macOS)
    private var workDurationBinding: Binding<Int> {
        Binding<Int>(
            get: { timer.workDuration / 60 },
            set: { timer.updateDurations(workMinutes: $0, shortBreakMinutes: timer.breakDuration / 60, longBreakMinutes: timer.longBreakDuration / 60) }
        )
    }
    
    private var shortBreakDurationBinding: Binding<Int> {
        Binding<Int>(
            get: { timer.breakDuration / 60 },
            set: { timer.updateDurations(workMinutes: timer.workDuration / 60, shortBreakMinutes: $0, longBreakMinutes: timer.longBreakDuration / 60) }
        )
    }
    
    private var longBreakDurationBinding: Binding<Int> {
        Binding<Int>(
            get: { timer.longBreakDuration / 60 },
            set: { timer.updateDurations(workMinutes: timer.workDuration / 60, shortBreakMinutes: timer.breakDuration / 60, longBreakMinutes: $0) }
        )
    }
    #endif
    
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
            }
        }
        .frame(width: ringSize, height: ringSize)
    }
    
    @ViewBuilder
    private func optionsControl(buttonSize: CGFloat) -> some View {
        #if os(macOS)
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

            Toggle("Auto-start next session", isOn: $timer.autoStartNextSession)

            Divider()

            Button("Analytics & Insights…") {
                showingAnalytics = true
            }

            Divider()

            if authManager.isSignedIn {
                if let name = authManager.displayName, !name.isEmpty {
                    Text(name)
                } else if let email = authManager.email, !email.isEmpty {
                    Text(email)
                }
                Button("Sign Out", role: .destructive) {
                    Task { await authManager.signOut() }
                }
            } else {
                Button("Sign In with Google") {
                    Task {
                        do {
                            try await authManager.signInWithGoogle()
                        } catch {
                            print("Sign-in failed: \(error)")
                        }
                    }
                }
            }

            Divider()

            Button("Reset to Defaults", role: .destructive, action: timer.resetDurationsToDefaults)

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
        #endif
    }
    
    private func playPauseButton(buttonSize: CGFloat) -> some View {
        Button {
            timer.isRunning ? timer.pause() : startWithPermission()
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
            timer.reset()
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
        timer.start()
    }
    
    private func playChime() {
        #if os(iOS) || os(macOS)
        guard let soundURL = Bundle.main.url(forResource: "chime-sound", withExtension: "mp3") else { return }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.play()
        } catch {
            // ignore
        }
        #endif
    }
}

// MARK: - Helper Views
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
    ContentView()
        .environmentObject(PomodoroTimer())
        .environmentObject(SessionLogger())
        .environmentObject(AuthManager())
        .environmentObject(AnalyticsManager(
            apiClient: AnalyticsApiClient(baseURL: URL(string: "https://api.example.com")!),
            authManager: AuthManager()
        ))
}
