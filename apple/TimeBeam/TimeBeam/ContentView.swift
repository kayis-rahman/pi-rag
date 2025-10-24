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
    // Use the shared PomodoroTimer so this compiles across platforms
    @EnvironmentObject var timer: TimeBeamShared.PomodoroTimer
    #if os(iOS) || os(macOS)
    @State private var audioPlayer: AVAudioPlayer?
    #endif
    @State private var lastPhase: TimeBeamShared.PomodoroTimer.Phase = .work
    @State private var didRequestNotificationPermission: Bool = UserDefaults.standard.bool(forKey: "didRequestNotificationPermission")

    private let ringSize: CGFloat = 220
    private let ringLineWidth: CGFloat = 14

    var body: some View {
        ZStack {
            #if os(macOS)
            Color(NSColor.windowBackgroundColor).ignoresSafeArea()
            #elseif os(iOS)
            Color(.systemBackground).ignoresSafeArea()
            #else
            Color.clear.ignoresSafeArea()
            #endif

            VStack(spacing: 24) {
                ZStack {
                    // Background circle (track)
                    Circle()
                        .stroke(Color.secondary.opacity(0.12), lineWidth: ringLineWidth)
                        .frame(width: ringSize, height: ringSize)

                    // Progress arc with dynamic color
                    Circle()
                        .trim(from: 0, to: timer.progress)
                        .stroke(
                            AngularGradient(gradient: Gradient(colors: [
                                timer.phase == .work ? Color.accentColor : Color.green,
                                timer.phase == .work ? Color.accentColor.opacity(0.6) : Color.green.opacity(0.6)
                            ]), center: .center),
                            style: StrokeStyle(lineWidth: ringLineWidth, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: ringSize, height: ringSize)

                    // Time and subtitle with dynamic color and text
                    VStack(spacing: 6) {
                        Text(timer.remainingSeconds.mmss)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(Color.primary)
                        Text(timer.phase == .work ? "just focus" : "break time!")
                            .font(.subheadline)
                            .foregroundStyle(Color.secondary)
                    }
                }
                .padding(.vertical, 8)

                // Controls
                HStack(spacing: 40) {
                    Button {
                        timer.isRunning ? timer.pause() : startWithPermission()
                    } label: {
                        Label(timer.isRunning ? "Pause" : "Start", systemImage: timer.isRunning ? "pause.fill" : "play.fill")
                            .labelStyle(.iconOnly)
                            .font(.system(size: 26, weight: .bold))
                            .padding(16)
                    }
                    .buttonStyle(.borderedProminent)
                    .clipShape(Circle())
                    .padding(.horizontal, 8)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 24)
            }
            .frame(maxHeight: .infinity)
        }
        .onAppear {
            lastPhase = timer.phase
        }
        .onChange(of: timer.phase) { newPhase in
            if newPhase != lastPhase {
                playChime()
                NotificationManager.shared.sendSessionDoneNotification(phase: lastPhase.rawValue)
                lastPhase = newPhase
            }
        }
    }

    private func startWithPermission() {
        // Only request notification permission on iOS/macOS
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
        #else
        // no-op on watchOS
        #endif
    }
}

#Preview {
    ContentView()
        .environmentObject(TimeBeamShared.PomodoroTimer())
}
