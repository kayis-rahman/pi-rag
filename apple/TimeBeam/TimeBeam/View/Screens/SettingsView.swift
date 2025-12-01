import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var timer: PomodoroTimer
    @EnvironmentObject var logger: SessionLogger
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("appTheme") private var appTheme = AppTheme.system

    enum AppTheme: String, CaseIterable {
        case light = "Light"
        case dark = "Dark"
        case system = "System"

        var displayName: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Timer Settings
                    SectionHeader(title: "Timer Settings")

                    VStack(spacing: 24) {
                        DurationSelectorRow(
                            title: "Focus Duration",
                            range: 15...60,
                            step: 5,
                            unit: "min",
                            value: Binding(
                                get: { timer.workDuration / 60 },
                                set: { timer.updateDurations(workMinutes: $0, shortBreakMinutes: timer.breakDuration / 60, longBreakMinutes: timer.longBreakDuration / 60) }
                            )
                        )

                        DurationSelectorRow(
                            title: "Break Duration",
                            range: 3...15,
                            step: 1,
                            unit: "min",
                            value: Binding(
                                get: { timer.breakDuration / 60 },
                                set: { timer.updateDurations(workMinutes: timer.workDuration / 60, shortBreakMinutes: $0, longBreakMinutes: timer.longBreakDuration / 60) }
                            )
                        )

                        DurationSelectorRow(
                            title: "Long Break Duration",
                            range: 10...30,
                            step: 5,
                            unit: "min",
                            value: Binding(
                                get: { timer.longBreakDuration / 60 },
                                set: { timer.updateDurations(workMinutes: timer.workDuration / 60, shortBreakMinutes: timer.breakDuration / 60, longBreakMinutes: $0) }
                            )
                        )

                        ToggleRow(
                            title: "Auto-start next session",
                            subtitle: "Automatically begin the next timer when one completes",
                            isOn: $timer.autoStartNextSession
                        )
                    }

                    // Sound & Haptics
                    SectionHeader(title: "Sound & Haptics")

                    VStack(spacing: 16) {
                        ToggleRow(
                            title: "Sound",
                            subtitle: "Play chime sounds when sessions start/end",
                            isOn: $soundEnabled
                        )

                        ToggleRow(
                            title: "Haptics",
                            subtitle: "Vibrate for session transitions",
                            isOn: $hapticsEnabled
                        )
                    }

                    // Appearance
                    SectionHeader(title: "Appearance")

                    VStack(spacing: 16) {
                        ThemePicker(selectedTheme: $appTheme)
                    }

                    // Account
                    SectionHeader(title: "Account")

                    VStack(spacing: 16) {
                        AccountSection()
                    }

                    // About
                    SectionHeader(title: "About")

                    VStack(spacing: 16) {
                        InfoRow(title: "Version", value: "1.0.0")
                        InfoRow(title: "Privacy Policy", value: "View Policy", isLink: true)
                    }

                    // Actions
                    VStack(spacing: 12) {
                        SecondaryButton(
                            title: "Reset to Defaults",
                            icon: "arrow.counterclockwise",
                            action: resetToDefaults
                        )

                        SecondaryButton(
                            title: "Clear All Data",
                            icon: "trash",
                            isDestructive: true,
                            action: clearAllData
                        )
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .background(Color.themeBackground.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func resetToDefaults() {
        timer.resetDurationsToDefaults()
        soundEnabled = true
        hapticsEnabled = true
        appTheme = .system
    }

    private func clearAllData() {
        // Show confirmation alert
        logger.clear()
    }
}

// MARK: - Supporting Views

struct ThemePicker: View {
    @Binding var selectedTheme: SettingsView.AppTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("App Theme")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color.themeTextPrimary)

            HStack(spacing: 12) {
                ForEach(SettingsView.AppTheme.allCases, id: \.self) { theme in
                    ThemeOption(
                        theme: theme,
                        isSelected: selectedTheme == theme,
                        action: { selectedTheme = theme }
                    )
                }
            }
        }
    }
}

struct ThemeOption: View {
    let theme: SettingsView.AppTheme
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(themePreviewColor)
                        .frame(width: 60, height: 40)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isSelected ? Color.themePrimary : Color.themeBorder, lineWidth: isSelected ? 2 : 1)
                        )

                    // Simple theme indicator
                    if theme == .dark {
                        Circle()
                            .fill(.white.opacity(0.8))
                            .frame(width: 16, height: 16)
                    } else if theme == .light {
                        Circle()
                            .fill(.black.opacity(0.6))
                            .frame(width: 16, height: 16)
                    } else {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(.black.opacity(0.6))
                                .frame(width: 6, height: 6)
                            Circle()
                                .fill(.white.opacity(0.8))
                                .frame(width: 6, height: 6)
                        }
                    }
                }

                Text(theme.displayName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? Color.themePrimary : Color.themeTextSecondary)
            }
        }
        .buttonStyle(.plain)
    }

    private var themePreviewColor: Color {
        switch theme {
        case .light: return .white
        case .dark: return .black
        case .system: return Color.themeCardBackground
        }
    }
}

struct AccountSection: View {
    // This would integrate with your AuthManager
    var body: some View {
        VStack(spacing: 16) {
            // Placeholder for account status
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Not signed in")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.themeTextPrimary)

                    Text("Sign in to sync your data across devices")
                        .font(.system(size: 14))
                        .foregroundColor(Color.themeTextSecondary)
                }

                Spacer()

                PrimaryButton(
                    title: "Sign In",
                    icon: "person.fill",
                    action: {
                        // Handle sign in
                    }
                )
                .frame(width: 100)
            }
            .padding(16)
            .background(Color.themeCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    var isLink: Bool = false

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(Color.themeTextPrimary)

            Spacer()

            if isLink {
                Text(value)
                    .font(.system(size: 16))
                    .foregroundColor(Color.themePrimary)
                    .underline()
            } else {
                Text(value)
                    .font(.system(size: 16))
                    .foregroundColor(Color.themeTextSecondary)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    SettingsView()
        .environmentObject(PomodoroTimer())
        .environmentObject(SessionLogger())
}
