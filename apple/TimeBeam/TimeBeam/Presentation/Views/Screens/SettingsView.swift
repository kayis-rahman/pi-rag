import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var timer: PomodoroTimer
    @EnvironmentObject var logger: SessionLogger
    @EnvironmentObject var authManager: AuthManager
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
            Form {
                // Sync & Cloud Section
                Section("SYNC & CLOUD") {
                    if authManager.isSignedIn {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(displayNameForProfile())
                                        .font(.system(size: 16, weight: .medium))
                                    Text(displayEmailForProfile())
                                        .font(.system(size: 14))
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundStyle(.blue)
                            }
                        }
                        .onAppear {
                            // Refresh auth data if it's incomplete
                            if authManager.displayName?.isEmpty ?? true || authManager.email?.isEmpty ?? true {
                                Task {
                                    await authManager.restoreSession()
                                }
                            }
                        }
                    } else {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Google Sign-In")
                                    .font(.system(size: 16, weight: .medium))
                                Text("Sync data across devices")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("Sign In") {
                                Task {
                                    do {
                                        try await authManager.signInWithGoogle()
                                    } catch {
                                        print("Sign-in failed: \(error)")
                                    }
                                }
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.blue)
                        }
                    }

                    NavigationLink("Manage Account") {
                        AccountManagementView()
                    }
                }

                // Timer Settings Section
                Section("Timer Settings") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Work Duration")
                            .font(.system(size: 16, weight: .medium))
                        Stepper(
                            "\(timer.workDuration / 60) min",
                            value: Binding(
                                get: { timer.workDuration / 60 },
                                set: { timer.updateDurations(workMinutes: $0, shortBreakMinutes: timer.breakDuration / 60, longBreakMinutes: timer.longBreakDuration / 60) }
                            ),
                            in: 15...60,
                            step: 5
                        )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Break Duration")
                            .font(.system(size: 16, weight: .medium))
                        Stepper(
                            "\(timer.breakDuration / 60) min",
                            value: Binding(
                                get: { timer.breakDuration / 60 },
                                set: { timer.updateDurations(workMinutes: timer.workDuration / 60, shortBreakMinutes: $0, longBreakMinutes: timer.longBreakDuration / 60) }
                            ),
                            in: 3...15,
                            step: 1
                        )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Long Break Duration")
                            .font(.system(size: 16, weight: .medium))
                        Stepper(
                            "\(timer.longBreakDuration / 60) min",
                            value: Binding(
                                get: { timer.longBreakDuration / 60 },
                                set: { timer.updateDurations(workMinutes: timer.workDuration / 60, shortBreakMinutes: timer.breakDuration / 60, longBreakMinutes: $0) }
                            ),
                            in: 10...30,
                            step: 5
                        )
                    }

                    Toggle("Auto-start next session", isOn: $timer.autoStartNextSession)
                }

                // Sound & Haptics Section
                Section("Sound & Haptics") {
                    Toggle("Sound", isOn: $soundEnabled)
                    Toggle("Haptics", isOn: $hapticsEnabled)
                }

                // App Theme Section
                Section("Appearance") {
                    Picker("App Theme", selection: $appTheme) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            Text(theme.displayName).tag(theme)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // About Section
                Section("ABOUT") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }

                    Button("Privacy Policy") {
                        // Open privacy policy URL
                    }
                    .foregroundStyle(.blue)
                }

                // Actions Section
                Section {
                    Button("Reset to Defaults", role: .destructive) {
                        resetToDefaults()
                    }

                    Button("Clear All Data", role: .destructive) {
                        clearAllData()
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func resetToDefaults() {
        timer.resetDurationsToDefaults()
        soundEnabled = true
        hapticsEnabled = true
        appTheme = .system
    }

    private func displayNameForProfile() -> String {
        if let name = authManager.displayName, !name.isEmpty {
            return name
        }
        // Try to extract name from email if available
        if let email = authManager.email, !email.isEmpty {
            let components = email.split(separator: "@")
            if let localPart = components.first {
                return String(localPart).replacingOccurrences(of: ".", with: " ").capitalized
            }
        }
        return "TimeBeam User"
    }

    private func displayEmailForProfile() -> String {
        if let email = authManager.email, !email.isEmpty {
            return email
        }
        return "Sign in to sync data"
    }

    private func clearAllData() {
        // Show confirmation alert
        logger.clear()
    }
}

// MARK: - Supporting Views

struct AccountManagementView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        Form {
            if authManager.isSignedIn {
                Section("ACCOUNT") {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(authManager.displayName ?? "User")
                                .font(.system(size: 16, weight: .medium))
                            Text(authManager.email ?? "")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.blue)
                    }
                }

                Section {
                    Button("Sign Out", role: .destructive) {
                        Task { await authManager.signOut() }
                    }
                }
            } else {
                Section("ACCOUNT") {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Not signed in")
                                .font(.system(size: 16, weight: .medium))
                            Text("Sign in to sync your data")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "person.circle")
                            .font(.system(size: 32))
                            .foregroundStyle(.secondary)
                    }

                    Button("Sign In with Google") {
                        Task {
                            do {
                                try await authManager.signInWithGoogle()
                            } catch {
                                print("Sign-in failed: \(error)")
                            }
                        }
                    }
                    .foregroundStyle(.blue)
                }
            }
        }
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    SettingsView()
        .environmentObject(PomodoroTimer())
        .environmentObject(SessionLogger())
        .environmentObject(AuthManager())
}
