import SwiftUI

struct CircularTimerView: View {
    @Environment(PomodoroTimer.self) var timer

    let size: CGFloat
    let showSessionProgress: Bool

    init(size: CGFloat = 280, showSessionProgress: Bool = true) {
        self.size = size
        self.showSessionProgress = showSessionProgress
    }

    var body: some View {
        let ringWidth = size * 0.055
        let ringFrame = size * 0.88

        ZStack {
            // Single glass backing disc
            Circle()
                .frame(width: size, height: size)
                .glassEffectInteractiveConditional(tint: phaseTint, in: Circle())

            // Track ring — guide rail for progress
            Circle()
                .stroke(Color.themeTextSecondary.opacity(0.2), lineWidth: ringWidth)
                .frame(width: ringFrame, height: ringFrame)

            // Progress ring
            Circle()
                .trim(from: 0, to: timer.progress)
                .stroke(
                    angularGradient(for: timer.phase),
                    style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: ringFrame, height: ringFrame)

            // Pulsing glow when running
            if timer.isRunning {
                Circle()
                    .stroke(phaseBorder.opacity(0.35), lineWidth: ringWidth)
                    .frame(width: ringFrame, height: ringFrame)
                    .scaleEffect(1.04)
                    .opacity(0.5)
                    .animation(
                        .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                        value: timer.isRunning
                    )
            }

            // Text content — sits directly on glass
            VStack(spacing: size * 0.02) {
                Text(timer.remainingSeconds.mmss)
                    .font(.system(size: size * 0.20, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.themeTextPrimary)

                Text(timer.phase.displayName)
                    .font(.system(size: size * 0.065, weight: .medium, design: .rounded))
                    .foregroundColor(.themeTextSecondary.opacity(0.75))

                if showSessionProgress {
                    Text("Cycle \(timer.shortBreaksCompleted + 1) of \(timer.cycleSize)")
                        .font(.system(size: size * 0.045, weight: .regular, design: .rounded))
                        .foregroundColor(.themeTextSecondary.opacity(0.5))
                        .padding(.top, size * 0.02)
                }
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel("CircularTimerView")
    }

    private func angularGradient(for phase: Phase) -> AngularGradient {
        switch phase {
        case .work:
            AngularGradient(
                gradient: Gradient(colors: [.themePrimary, .themeAccent]),
                center: .center,
                startAngle: .degrees(0),
                endAngle: .degrees(360)
            )
        case .break:
            AngularGradient(
                gradient: Gradient(colors: [.themeOrangePrimary, .themeOrangeAccent]),
                center: .center,
                startAngle: .degrees(0),
                endAngle: .degrees(360)
            )
        case .longBreak:
            AngularGradient(
                gradient: Gradient(colors: [.themeOrangeAccent, .themeOrangeDeep]),
                center: .center,
                startAngle: .degrees(0),
                endAngle: .degrees(360)
            )
        }
    }

    private var phaseTint: Color {
        switch timer.phase {
        case .work:      LiquidGlass.primaryTint.opacity(0.45)
        case .break:     LiquidGlass.warningTint.opacity(0.45)
        case .longBreak: LiquidGlass.warningTint.opacity(0.55)
        }
    }

    private var phaseBorder: Color {
        switch timer.phase {
        case .work:      LiquidGlass.primaryTint.opacity(0.5)
        case .break:     LiquidGlass.warningTint.opacity(0.5)
        case .longBreak: LiquidGlass.warningTint.opacity(0.6)
        }
    }
}

#Preview {
    CircularTimerView()
        .environment(PomodoroTimer())
}
