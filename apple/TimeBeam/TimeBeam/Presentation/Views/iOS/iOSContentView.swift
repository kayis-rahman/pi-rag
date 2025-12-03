import AuthenticationServices

import AVFoundation
import SwiftUI
import UserNotifications

struct iOSContentView: View {
    @EnvironmentObject var timer: PomodoroTimer
    @EnvironmentObject var logger: SessionLogger
    @EnvironmentObject var authManager: AuthManager
    @State private var audioPlayer: AVAudioPlayer?
    @State private var lastPhase: Phase = .work
    @State private var didRequestNotificationPermission: Bool = UserDefaults.standard.bool(forKey: "didRequestNotificationPermission")

    var body: some View {
        let ringSize: CGFloat = 280
        let ringLineWidth = max(10, ringSize * 0.065)

        ZStack {
            // Background
            Color.themeBackground.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Timer display
                CircularTimerView(size: ringSize, showSessionProgress: false)

                // Session progress indicator
                CycleProgressView(
                    completed: timer.shortBreaksCompleted,
                    total: timer.cycleSize
                )
                .frame(width: ringSize * 0.5)

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

    private func startWithPermission() {
        if !didRequestNotificationPermission {
            NotificationManager.shared.requestPermission { _ in }
            didRequestNotificationPermission = true
            UserDefaults.standard.set(true, forKey: "didRequestNotificationPermission")
        }
        timer.start()
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
    iOSContentView()
        .environmentObject(PomodoroTimer())
        .environmentObject(SessionLogger())
        .environmentObject(AuthManager())
}
