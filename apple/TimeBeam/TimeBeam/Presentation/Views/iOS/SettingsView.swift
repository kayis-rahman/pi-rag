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
            List {
                // Sync & Cloud Section
                Section("SYNC & CLOUD") {
                    if authManager.isSignedIn {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    if !displayNameForProfile().isEmpty {
                                        Text(displayNameForProfile())
                                            .font(.system(size: 16, weight: .medium))
                                    }
                                    if !displayEmailForProfile().isEmpty {
                                        Text(displayEmailForProfile())
                                            .font(.system(size: 14))
                                            .foregroundStyle(.secondary)
                                    }
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
                                 _Concurrency.Task {
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
                                 _Concurrency.Task {
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
                                set: {
                                    timer.updateDurations(workMinutes: $0, shortBreakMinutes: timer.breakDuration / 60, longBreakMinutes: timer.longBreakDuration / 60)
                                    syncTimerSettingsToiCloud()
                                }
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
                                set: {
                                    timer.updateDurations(workMinutes: timer.workDuration / 60, shortBreakMinutes: $0, longBreakMinutes: timer.longBreakDuration / 60)
                                    syncTimerSettingsToiCloud()
                                }
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
                                set: {
                                    timer.updateDurations(workMinutes: timer.workDuration / 60, shortBreakMinutes: timer.breakDuration / 60, longBreakMinutes: $0)
                                    syncTimerSettingsToiCloud()
                                }
                            ),
                            in: 10...30,
                            step: 5
                        )
                    }

                    Toggle("Auto-start next session", isOn: $timer.autoStartNextSession)
                        .onChange(of: timer.autoStartNextSession) { _ in
                            syncTimerSettingsToiCloud()
                        }
                }

                // Manual Sync Section (for testing)
                Section("MANUAL SYNC") {
                    Button("Sync Timer State Now") {
                        Task {
                            print("🔄 MANUAL_SYNC: User triggered manual sync")
                            await TimerSyncManager.shared.syncTimerState()
                        }
                    }
                    .foregroundColor(.blue)
                    Text("Manually sync timer state with other devices")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
                        Text(Bundle.main.displayVersion)
                            .foregroundStyle(.secondary)
                    }

                    Button("Privacy Policy") {
                        openPrivacyPolicy()
                    }
                    .foregroundStyle(.blue)

                    Button("Help & Support") {
                        openHelpAndSupport()
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
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
        }
    }

    private func resetToDefaults() {
        timer.resetDurationsToDefaults()
        soundEnabled = true
        hapticsEnabled = true
        appTheme = .system
        syncTimerSettingsToiCloud()
    }

    private func syncTimerSettingsToiCloud() {
        let settings = TimerSettings(
            workDuration: timer.workDuration,
            breakDuration: timer.breakDuration,
            longBreakDuration: timer.longBreakDuration,
            autoStartNextSession: timer.autoStartNextSession
        )
        iCloudSyncManager.shared.syncTimerSettings(settings)
    }

    private func displayNameForProfile() -> String {
        if let name = authManager.displayName, !name.isEmpty {
            return name
        }
        return ""
    }

    private func displayEmailForProfile() -> String {
        if let email = authManager.email, !email.isEmpty {
            return email
        }
        return ""
    }

    private func clearAllData() {
        // Show confirmation alert
        logger.clear()
    }

    private func openPrivacyPolicy() {
        guard let url = URL(string: "https://timebeam.app/privacy") else { return }
        #if os(iOS)
        UIApplication.shared.open(url)
        #else
        NSWorkspace.shared.open(url)
        #endif
    }

    private func openHelpAndSupport() {
        guard let url = URL(string: "https://timebeam.app/help") else { return }
        #if os(iOS)
        UIApplication.shared.open(url)
        #else
        NSWorkspace.shared.open(url)
        #endif
    }
}

// MARK: - Supporting Views

struct AccountManagementView: View {
    @EnvironmentObject var authManager: AuthManager

    // Device stats state
    @State private var deviceStats: ApiClient.DeviceStats?
    @State private var isLoadingDeviceStats = false
    @State private var deviceStatsError: String?

    var body: some View {
        List {
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

                // Device Statistics Section
                Section("DEVICES") {
                    if isLoadingDeviceStats {
                        HStack {
                            ProgressView()
                            Text("Loading device info...")
                                .foregroundStyle(.secondary)
                        }
                    } else if let stats = deviceStats {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "iphone")
                                    .foregroundStyle(.blue)
                                Text("\(stats.activeDevices) Active Devices")
                                    .font(.system(size: 16, weight: .medium))
                                Spacer()
                                Text("\(stats.totalDevices) Total")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.secondary)
                            }

                            HStack(spacing: 16) {
                                deviceTypeBadge("iOS", count: stats.iosDevices, color: .blue)
                                deviceTypeBadge("macOS", count: stats.macosDevices, color: .orange)
                                deviceTypeBadge("watchOS", count: stats.watchosDevices, color: .green)
                            }
                        }
                    } else if let error = deviceStatsError {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundStyle(.orange)
                            Text("Couldn't load device info")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button("Retry") {
                                loadDeviceStats()
                            }
                            .font(.system(size: 14))
                        }
                    }
                }

                Section {
                     Button("Sign Out", role: .destructive) {
                         _Concurrency.Task { await authManager.signOut() }
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
                         _Concurrency.Task {
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
        .onAppear {
            if authManager.isSignedIn && deviceStats == nil {
                loadDeviceStats()
            }
        }
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
    }

    // MARK: - Device Stats Functions

    private func loadDeviceStats() {
        guard authManager.isSignedIn else { return }

        isLoadingDeviceStats = true
         deviceStatsError = nil

         _Concurrency.Task {
            do {
                guard let config = ApiClient.Configuration.fromInfoPlist(),
                      let accessToken = try? KeychainStore.loadString(.accessToken) else {
                    throw NSError(domain: "DeviceStats", code: -1,
                                userInfo: [NSLocalizedDescriptionKey: "Missing configuration"])
                }

                let apiClient = ApiClient(configuration: config)
                let stats = try await apiClient.getDeviceStats(accessToken: accessToken)

                await MainActor.run {
                    self.deviceStats = stats
                    self.isLoadingDeviceStats = false
                }
            } catch {
                await MainActor.run {
                    self.deviceStatsError = error.localizedDescription
                    self.isLoadingDeviceStats = false
                }
            }
        }
    }

    private func deviceTypeBadge(_ type: String, count: Int, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: type.lowercased() == "ios" ? "iphone" :
                         type.lowercased() == "macos" ? "laptopcomputer" : "applewatch")
                .foregroundStyle(color)
            Text("\(count)")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    SettingsView()
        .environmentObject(PomodoroTimer())
        .environmentObject(SessionLogger())
        .environmentObject(AuthManager())
}
