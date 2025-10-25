//
//  ContentView.swift
//  TimeBeam
//
//  Created by Kayis Rahman on 15/09/25.
//

import SwiftUI
#if os(iOS) || os(macOS)
import AVFoundation
#endif
import UserNotifications
#if os(macOS)
import AppKit
#endif
import TimeBeamShared

struct ContentView: View {
    @EnvironmentObject var timer: TimeBeamShared.PomodoroTimer
    #if os(iOS) || os(macOS)
    @State private var audioPlayer: AVAudioPlayer?
    #endif
    @State private var lastPhase: TimeBeamShared.PomodoroTimer.Phase = .work
    @State private var didRequestNotificationPermission: Bool = UserDefaults.standard.bool(forKey: "didRequestNotificationPermission")
    @State private var showingOptions: Bool = false

    var body: some View {
        let ringSize: CGFloat = 280
        let ringLineWidth = max(10, ringSize * 0.065)
        let buttonSize: CGFloat = 54

        VStack(spacing: 40) {
            timerRing(ringSize: ringSize, ringLineWidth: ringLineWidth, buttonSize: buttonSize)
            
            HStack(spacing: 40) {
                resetButton(buttonSize: buttonSize)
                optionsButton(buttonSize: buttonSize)
            }
        }
        .padding(40)
        .background(Color.themeBackground.ignoresSafeArea())
        .sheet(isPresented: $showingOptions) {
            SettingsView()
                .environmentObject(timer)
        }
        .onAppear {
            lastPhase = timer.phase
        }
        .onChange(of: timer.phase) { oldPhase, newPhase in
            if newPhase != oldPhase {
                playChime()
                // Notification is now sent from within the timer model to ensure it's sent on all platforms.
                lastPhase = newPhase
            }
        }
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

                Text(timer.phase == .work ? "just focus " : "break time!")
                    .font(.system(size: ringSize * 0.08, weight: .regular))
                    .foregroundStyle(Color.themeTextSecondary)
                
                if timer.phase == .work {
                    CycleProgressView(
                        completed: timer.shortBreaksCompleted,
                        total: timer.cycleSize
                    )
                    .frame(width: ringSize * 0.5)
                }
                playPauseButton(buttonSize: buttonSize)
            }
        }
        .frame(width: ringSize, height: ringSize)
    }

    private func optionsButton(buttonSize: CGFloat) -> some View {
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
        #if os(iOS) || os(macOS)
        if !didRequestNotificationPermission {
            NotificationManager.shared.requestPermission { _ in }
            didRequestNotificationPermission = true
            UserDefaults.standard.set(true, forKey: "didRequestNotificationPermission")
        }
        #endif
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

private struct SettingsView: View {
    @EnvironmentObject var timer: TimeBeamShared.PomodoroTimer
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

                Section {
                    Button("Reset to Defaults", role: .destructive, action: timer.resetDurationsToDefaults)
                }
            }
            .navigationTitle("Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            #endif
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
                Text("\(duration / 60)m").foregroundStyle(.secondary)
            }
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
        #if os(iOS)
        .pickerStyle(.wheel)
        #else
        .pickerStyle(.automatic)
        .padding()
        #endif
        .navigationTitle(title)
        .onDisappear {
            onSelect(selectedMinutes)
        }
    }
}

// MARK: - Theming Extensions

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
    // Static colors that do not change with light/dark mode
    static let themePrimary   = Color(hex: "#E07A5F") // Terracotta
    static let themeAccent    = Color(hex: "#F4F1DE") // Sand Beige
    static let themeSecondary = Color(hex: "#81B29A") // Olive

    // Dynamic colors that adapt to light/dark mode for iOS and macOS
    #if os(iOS)
    static let themeBackground = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: "#2C1F18") : UIColor(hex: "#FAF8F5") })
    static let themeTextPrimary = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: "#F4F1DE") : UIColor(hex: "#272220") })
    static let themeTextSecondary = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: "#81B29A") : UIColor(hex: "#6C5E55") })
    #elseif os(macOS)
    static let themeBackground = Color(NSColor(name: nil, dynamicProvider: { $0.name == .darkAqua ? NSColor(hex: "#2C1F18") : NSColor(hex: "#FAF8F5") }))
    static let themeTextPrimary = Color(NSColor(name: nil, dynamicProvider: { $0.name == .darkAqua ? NSColor(hex: "#F4F1DE") : NSColor(hex: "#272220") }))
    static let themeTextSecondary = Color(NSColor(name: nil, dynamicProvider: { $0.name == .darkAqua ? NSColor(hex: "#81B29A") : NSColor(hex: "#6C5E55") }))
    #endif

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

#if os(iOS) || os(macOS)
private extension CrossPlatformColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}

#if os(iOS)
private typealias CrossPlatformColor = UIColor
#elseif os(macOS)
private typealias CrossPlatformColor = NSColor
#endif
#endif


#Preview {
    ContentView()
        .environmentObject(TimeBeamShared.PomodoroTimer())
}
