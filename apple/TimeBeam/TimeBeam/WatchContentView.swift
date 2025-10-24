import SwiftUI
import TimeBeamShared

struct WatchContentView: View {
    @EnvironmentObject private var timer: TimeBeamShared.PomodoroTimer
    @State private var didRequestNotificationPermission: Bool = UserDefaults.standard.bool(forKey: "didRequestNotificationPermission")
    @State private var showingOptions: Bool = false

    var body: some View {
        GeometryReader { proxy in
            // Use the smaller side to size the ring more consistently across watch sizes
            let minSide = proxy.size.width - 40
            let ringSize = minSide
            let ringLineWidth = max(8, ringSize * 0.065)

            // Buttons
            let buttonSize = max(32, minSide * 0.18)
            let cornerPadding: CGFloat = 4

            ZStack {
                Color.clear.ignoresSafeArea()

                // Pin content to the top (no clock)
                VStack(spacing: minSide * 0.02) {
                    
                    Spacer(minLength: 10)
                    // Ring
                    ZStack {
                        // Track
                        Circle()
                            .stroke(Color.secondary.opacity(0.12), lineWidth: ringLineWidth)
                            .frame(width: ringSize, height: ringSize)

                        // Progress arc
                        Circle()
                            .trim(from: 0, to: timer.progress)
                            .stroke(
                                AngularGradient(
                                    gradient: Gradient(colors: [
                                        timer.phase == .work ? .accentColor : .green,
                                        timer.phase == .work ? .accentColor.opacity(0.6) : .green.opacity(0.6)
                                    ]),
                                    center: .center
                                ),
                                style: StrokeStyle(lineWidth: ringLineWidth, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .frame(width: ringSize, height: ringSize)

                        // Countdown + subtitle inside ring
                        VStack(spacing: minSide * 0.02) {
                            Text(timer.remainingSeconds.mmss)
                                .font(.system(size: ringSize * 0.18, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundColor(.primary)

                            Text(timer.phase == .work ? "just focus" : "break time!")
                                .font(.system(size: ringSize * 0.08, weight: .regular))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)

                    // Spacer to allow corner buttons to sit at the bottom while content stays towards the top
                    Spacer(minLength: 15)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            // Top-left: Options (moved from top-right)
            .overlay(alignment: .topLeading) {
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
                .padding(.top, cornerPadding)
                .padding(.leading, cornerPadding)
            }
            // Bottom-left: Start/Pause
            .overlay(alignment: .bottomLeading) {
                Button {
                    timer.isRunning ? timer.pause() : startWithPermission()
                } label: {
                    Image(systemName: timer.isRunning ? "pause.fill" : "play.fill")
                        .frame(width: buttonSize, height: buttonSize)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Pause/Start")
                .padding(.bottom, cornerPadding)
                .padding(.leading, cornerPadding)
            }
            // Bottom-right: Reset
            .overlay(alignment: .bottomTrailing) {
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
                .padding(.bottom, cornerPadding)
                .padding(.trailing, cornerPadding)
            }
            .sheet(isPresented: $showingOptions) {
                OptionsView(timer: timer)
            }
        }
        .onChange(of: timer.phase) { oldPhase, newPhase in
            if newPhase != oldPhase {
                NotificationManager.shared.sendSessionDoneNotification(phase: oldPhase.rawValue)
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
}

private struct OptionsView: View {
    @ObservedObject var timer: TimeBeamShared.PomodoroTimer

    var body: some View {
        VStack(spacing: 12) {
            Text("Options")
                .font(.headline)
            Text("Add settings here")
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    WatchContentView()
        .environmentObject(TimeBeamShared.PomodoroTimer())
}
