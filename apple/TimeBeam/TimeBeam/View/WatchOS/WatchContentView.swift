import SwiftUI
import Combine

struct WatchContentView: View {
    @EnvironmentObject private var timer: PomodoroTimer
    @EnvironmentObject private var logger: SessionLogger
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var wcManager: WatchConnectivityManager

    @State private var didRequestNotificationPermission: Bool = UserDefaults.standard.bool(forKey: "didRequestNotificationPermission")
    @State private var showingOptions: Bool = false

    var body: some View {
        GeometryReader { proxy in
            let minSide = proxy.size.width - 30
            let ringLineWidth = max(8, minSide * 0.065)
            let buttonSize = max(32, minSide * 0.18)
            let cornerPadding: CGFloat = 4
            
            ZStack {
                Color.themeBackground

                VStack(spacing: minSide * 0.02) {
                    Spacer(minLength: 25)
                    timerRing(ringSize: minSide, ringLineWidth: ringLineWidth)
                    Spacer(minLength: 25)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .overlay(alignment: .topLeading) {
                optionsButton(buttonSize: buttonSize, padding: cornerPadding)
            }
            .overlay(alignment: .bottomLeading) {
                playPauseButton(buttonSize: buttonSize, padding: cornerPadding)
            }
            .overlay(alignment: .bottomTrailing) {
                resetButton(buttonSize: buttonSize, padding: cornerPadding)
            }
            .ignoresSafeArea()
            .sheet(isPresented: $showingOptions) {
                SettingsView()
                    .environmentObject(timer)
                    .environmentObject(logger)
                    .environmentObject(authManager)
                    .environmentObject(wcManager)
            }
        }
        .onAppear {
            Task { await authManager.restoreSession() }
        }
    }

    private func timerRing(ringSize: CGFloat, ringLineWidth: CGFloat) -> some View {
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

            VStack(spacing: ringSize * 0.05) {
                Text(timer.remainingSeconds.mmss)
                    .font(.system(size: ringSize * 0.18, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Color.themeTextPrimary)

                Text(timer.phase == .work ? "just focus" : "break time!")
                    .font(.system(size: ringSize * 0.1, weight: .regular))
                    .foregroundStyle(Color.themeTextSecondary)
                
                if timer.phase == .work {
                    CycleProgressView(
                        completed: timer.shortBreaksCompleted,
                        total: timer.cycleSize
                    )
                    .frame(width: ringSize * 0.5)
                }
            }
        }
        .frame(width: ringSize, height: ringSize)
    }

    private func optionsButton(buttonSize: CGFloat, padding: CGFloat) -> some View {
        Button {
            showingOptions = true
        } label: {
            Image(systemName: "gearshape.fill")
                .frame(width: buttonSize, height: buttonSize)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Options")
        .padding([.top, .leading], padding)
    }

    private func playPauseButton(buttonSize: CGFloat, padding: CGFloat) -> some View {
        Button {
            timer.isRunning ? timer.pause() : startWithPermission()
        } label: {
            Image(systemName: timer.isRunning ? "pause.fill" : "play.fill")
                .frame(width: buttonSize, height: buttonSize)
                .background(Color.themePrimary)
                .foregroundStyle(Color.themeAccent)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(timer.isRunning ? "Pause" : "Start")
        .padding([.bottom, .leading], padding)
    }

    private func resetButton(buttonSize: CGFloat, padding: CGFloat) -> some View {
        Button {
            timer.reset()
        } label: {
            Image(systemName: "arrow.counterclockwise")
                .frame(width: buttonSize, height: buttonSize)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Reset")
        .padding([.bottom, .trailing], padding)
    }

    private func startWithPermission() {
        if !didRequestNotificationPermission {
            NotificationManager.shared.requestPermission { _ in }
            didRequestNotificationPermission = true
            UserDefaults.standard.set(true, forKey: "didRequestNotificationPermission")
        }
        timer.start()
    }
}

private struct CycleProgressView: View {
    let completed: Int
    let total: Int

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<total, id: \.self) { index in
                Circle()
                    .fill(index < completed ? Color.themePrimary : Color.themeTextSecondary.opacity(0.3))
                    .frame(width: 10, height: 10)
            }
        }
    }
}

private struct SettingsView: View {
    @EnvironmentObject var timer: PomodoroTimer
    @EnvironmentObject var logger: SessionLogger
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var wcManager: WatchConnectivityManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                durationPickerLink(for: .work)
                durationPickerLink(for: .break)
                durationPickerLink(for: .longBreak)

                Section {
                    Toggle("Auto-start next session", isOn: $timer.autoStartNextSession)
                }

                Section(header: Text("Account")) {
                    if authManager.isSignedIn {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Signed in")
                            if let name = authManager.displayName, !name.isEmpty {
                                Text(name).font(.footnote).foregroundStyle(Color.themeTextSecondary)
                            } else if let email = authManager.email, !email.isEmpty {
                                Text(email).font(.footnote).foregroundStyle(Color.themeTextSecondary)
                            }
                        }
                        Button(role: .destructive) {
                            Task { await authManager.signOut() }
                        } label: { Text("Sign out") }
                    } else {
                        Button {
                            wcManager.requestSignInOnPhone()
                        } label: {
                            HStack {
                                Image(systemName: "g.circle.fill")
                                Text("Sign in on your iPhone")
                            }
                        }
                        .accessibilityLabel("Sign in with Google on your iPhone")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                await authManager.restoreSession()
            }
        }
    }
    
    private func durationPickerLink(for phase: PomodoroTimer.Phase) -> some View {
        let (title, duration) = {
            switch phase {
            case .work: return ("Focus", timer.workDuration)
            case .break: return ("Short Break", timer.breakDuration)
            case .longBreak: return ("Long Break", timer.longBreakDuration)
            }
        }()
        
        return NavigationLink {
            MinutesPickerView(title: title, initialMinutes: duration / 60) { minutes in
                timer.updateDurations(
                    workMinutes: phase == .work ? minutes : timer.workDuration / 60,
                    shortBreakMinutes: phase == .break ? minutes : timer.breakDuration / 60,
                    longBreakMinutes: phase == .longBreak ? minutes : timer.longBreakDuration / 60
                )
            }
        } label: {
            HStack {
                Text(title)
                Spacer()
                Text("\(duration / 60)m").foregroundStyle(Color.themeTextSecondary)
            }
        }
    }
}

private struct MinutesPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let onSelect: (Int) -> Void
    @State private var selectedMinutes: Int
    private let minutesRange = Array(stride(from: 5, to: 121, by: 5))

    init(title: String, initialMinutes: Int, onSelect: @escaping (Int) -> Void) {
        self.title = title
        self.onSelect = onSelect
        let closest = minutesRange.min(by: { abs($0 - initialMinutes) < abs($1 - initialMinutes) }) ?? initialMinutes
        self._selectedMinutes = State(initialValue: closest)
    }

    var body: some View {
        VStack {
            Picker("Minutes", selection: $selectedMinutes) {
                ForEach(minutesRange, id: \.self) { Text("\($0) minutes").tag($0) }
            }
            .pickerStyle(.wheel)
            .labelsHidden()
            
            Button("Done") {
                onSelect(selectedMinutes)
                dismiss()
            }
        }
        .navigationTitle(title)
    }
}

#Preview {
    WatchContentView()
        .environmentObject(PomodoroTimer())
        .environmentObject(SessionLogger())
        .environmentObject(AuthManager())
        .environmentObject(WatchConnectivityManager())
}
