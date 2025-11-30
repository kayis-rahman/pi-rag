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
    #if os(iOS) || os(macOS)
    @EnvironmentObject var authManager: AuthManager
    #endif
    #if os(iOS) || os(macOS)
    @State private var audioPlayer: AVAudioPlayer?
    #endif
    @State private var lastPhase: Phase = .work
    @State private var didRequestNotificationPermission: Bool = UserDefaults.standard.bool(forKey: "didRequestNotificationPermission")
    @State private var showingOptions: Bool = false
    #if os(macOS)
    @State private var showingAnalytics: Bool = false
    #endif
    
    var body: some View {
        let ringSize: CGFloat = 280
        let ringLineWidth = max(10, ringSize * 0.065)
        let buttonSize: CGFloat = 54
        
        VStack(spacing: 10) {
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
        #if os(macOS)
        .sheet(isPresented: $showingAnalytics) {
            AnalyticsView()
                .environmentObject(logger)
        }
        #endif
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
                
                CycleProgressView(
                    completed: timer.shortBreaksCompleted,
                    total: timer.cycleSize
                )
                .frame(width: ringSize * 0.5)
                .padding(.bottom, 15)
                playPauseButton(buttonSize: buttonSize)
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
        #else
        Button {
            showingOptions = true
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
        .sheet(isPresented: $showingOptions) {
            SettingsView()
                .environmentObject(timer)
                .environmentObject(logger)
                #if os(iOS)
                .environmentObject(authManager)
                #endif
        }
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

#if os(iOS)
private struct SettingsView: View {
    @EnvironmentObject var timer: PomodoroTimer
    @EnvironmentObject var logger: SessionLogger
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Durations")) {
                    durationPickerLink(for: .work)
                    durationPickerLink(for: .break)
                    durationPickerLink(for: .longBreak)
                }
                
                Section(header: Text("Behavior")) {
                    Toggle("Auto-start next session", isOn: $timer.autoStartNextSession)
                }

                Section(header: Text("Analytics")) {
                    NavigationLink("Analytics & Insights") {
                        AnalyticsView()
                            .environmentObject(logger)
                    }
                }

                Section(header: Text("Account")) {
                    if authManager.isSignedIn {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Signed in")
                            if let name = authManager.displayName, !name.isEmpty {
                                Text(name).font(.footnote).foregroundStyle(.secondary)
                            } else if let email = authManager.email, !email.isEmpty {
                                Text(email).font(.footnote).foregroundStyle(.secondary)
                            }
                        }
                        Button(role: .destructive) {
                            Task { await authManager.signOut() }
                        } label: { Text("Sign out") }
                    } else {
                        Button {
                            Task {
                                let anchor = await currentPresentationAnchor()
                                do {
                                    try await authManager.signInWithGoogle(presentingAnchor: anchor)
                                } catch {
                                    print("Sign-in failed: \(error)")
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "g.circle.fill")
                                Text("Sign in with Google")
                            }
                        }
                        .accessibilityLabel("Sign in with Google")
                    }
                }
                
                Section {
                    Button("Reset to Defaults", role: .destructive, action: timer.resetDurationsToDefaults)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
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
                Text("\(duration / 60)m").foregroundStyle(.secondary)
            }
        }
    }

    private func currentPresentationAnchor() async -> ASPresentationAnchor? {
        await MainActor.run {
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return nil }
            return scene.windows.first
        }
    }
}

private struct MinutesPickerView: View {
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
        Picker("Minutes", selection: $selectedMinutes) {
            ForEach(minutesRange, id: \.self) { Text("\($0) minutes").tag($0) }
        }
        .pickerStyle(.wheel)
        .navigationTitle(title)
        .onDisappear {
            onSelect(selectedMinutes)
        }
    }
}
#endif

#Preview {
    ContentView()
        .environmentObject(PomodoroTimer())
        .environmentObject(SessionLogger())
        #if os(iOS) || os(macOS)
        .environmentObject(AuthManager())
        #endif
}
