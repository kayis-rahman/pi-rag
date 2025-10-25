import SwiftUI
import TimeBeamShared

struct WatchContentView: View {
    @EnvironmentObject private var timer: TimeBeamShared.PomodoroTimer
    @State private var didRequestNotificationPermission: Bool = UserDefaults.standard.bool(forKey: "didRequestNotificationPermission")
    @State private var showingOptions: Bool = false

    var body: some View {
        GeometryReader { proxy in
            let minSide = proxy.size.width - 30
            let ringSize = minSide
            let ringLineWidth = max(8, ringSize * 0.065)
            let buttonSize = max(32, minSide * 0.18)
            let cornerPadding: CGFloat = 4
            
            ZStack {
                Color.themeBackground

                VStack(spacing: minSide * 0.02) {
                    Spacer(minLength: 15)
                    timerRing(ringSize: ringSize, ringLineWidth: ringLineWidth)
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
            .safeAreaInset(edge: .top) {
                Color.cyan
                // This adds a small empty space at the very top of the screen.
                EmptyView().frame(height: 10)
            }
            .sheet(isPresented: $showingOptions) {
                SettingsView()
                    .environmentObject(timer)
            }
        }
        .onChange(of: timer.phase) { oldPhase, newPhase in
            if newPhase != oldPhase {
                // Notification is now sent from within the timer model to ensure it's sent on all platforms.
            }
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
    @EnvironmentObject var timer: TimeBeamShared.PomodoroTimer
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
    
    private func durationPickerLink(for phase: TimeBeamShared.PomodoroTimer.Phase) -> some View {
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

private extension AngularGradient {
    static func forThemePhase(_ phase: TimeBeamShared.PomodoroTimer.Phase) -> AngularGradient {
        let colors: [Color]
        switch phase {
        case .work: colors = [.themePrimary, .themePrimary.opacity(0.6)]
        case .break, .longBreak: colors = [.themeSecondary, .themeSecondary.opacity(0.6)]
        }
        return AngularGradient(gradient: Gradient(colors: colors), center: .center)
    }
}

private extension Color {
    // Static colors defined for the watchOS dark interface.
    static let themePrimary       = Color(hex: "#E07A5F") // Terracotta
    static let themeAccent        = Color(hex: "#F4F1DE") // Sand Beige
    static let themeSecondary     = Color(hex: "#81B29A") // Olive
    static let themeBackground    = Color(hex: "#2C1F18") // Background (Dark)
    static let themeTextPrimary   = Color(hex: "#F4F1DE") // Text (on Dark) -> Sand Beige
    static let themeTextSecondary = Color(hex: "#81B29A") // Text (on Dark) -> Olive

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}


#Preview {
    WatchContentView()
        .environmentObject(TimeBeamShared.PomodoroTimer())
}
