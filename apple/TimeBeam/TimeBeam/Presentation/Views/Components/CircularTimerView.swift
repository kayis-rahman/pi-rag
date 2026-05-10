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
        ZStack {
            // Outer glass effect timer ring with phase-appropriate tint
            Circle()
                .fill(phaseColor)
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .stroke(phaseBorder, lineWidth: size * 0.015)
                        .opacity(0.5)
                )
                .glassEffectInteractiveConditional(tint: phaseTint, in: Circle())

            // Progress circle (outer ring)
            Circle()
                .trim(from: 0, to: timer.progress)
                .stroke(
                    angularGradient(for: timer.phase),
                    style: StrokeStyle(
                        lineWidth: size * 0.04,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .frame(width: size, height: size)

            // Pulsing animation when active
            if timer.isRunning {
                Circle()
                    .stroke(phaseBorder.opacity(0.4), lineWidth: size * 0.04)
                    .frame(width: size, height: size)
                    .scaleEffect(1.05)
                    .opacity(0.6)
                    .animation(
                        .easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true),
                        value: timer.isRunning
                    )
            }

            // Inner glass disc behind content
            Circle()
                .frame(width: size * 0.75, height: size * 0.75)
                .glassEffectInteractiveConditional(tint: nil, in: Circle())

            // Content overlay
            VStack(spacing: size * 0.02) {
                // Time display
                Text(timer.remainingSeconds.mmss)
                    .font(.system(size: size * 0.18, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.themeTextPrimary)

                // PomodoroTimer.Phase label
                Text(timer.phase.displayName)
                    .font(.system(size: size * 0.06, weight: .medium, design: .rounded))
                    .foregroundColor(.themeTextSecondary.opacity(0.6))

                // Session progress (only show if requested)
                if showSessionProgress {
                    Text("Cycle \(timer.shortBreaksCompleted + 1) of \(timer.cycleSize)")
                        .font(.system(size: size * 0.04, weight: .regular, design: .rounded))
                        .foregroundColor(.themeTextSecondary.opacity(0.4))
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
                gradient: Gradient(colors: [
                    .themePrimary,
                    .themeAccent
                ]),
                center: .center,
                startAngle: .degrees(0),
                endAngle: .degrees(360)
            )
        case .break:
            AngularGradient(
                gradient: Gradient(colors: [
                    .themeOrangePrimary,
                    .themeOrangeAccent
                ]),
                center: .center,
                startAngle: .degrees(0),
                endAngle: .degrees(360)
            )
        case .longBreak:
            AngularGradient(
                gradient: Gradient(colors: [
                    .themeOrangeAccent,
                    .themeOrangeDeep
                ]),
                center: .center,
                startAngle: .degrees(0),
                endAngle: .degrees(360)
            )
        }
    }

    private var phaseColor: Color {
        switch timer.phase {
        case .work:
            LiquidGlass.primaryTint.opacity(0.1)
        case .break:
            LiquidGlass.warningTint.opacity(0.1)
        case .longBreak:
            LiquidGlass.warningTint.opacity(0.15)
        }
    }

    private var phaseTint: Color {
        switch timer.phase {
        case .work:
            LiquidGlass.primaryTint.opacity(0.25)
        case .break:
            LiquidGlass.warningTint.opacity(0.25)
        case .longBreak:
            LiquidGlass.warningTint.opacity(0.35)
        }
    }

    private var phaseBorder: Color {
        switch timer.phase {
        case .work:
            LiquidGlass.primaryTint.opacity(0.5)
        case .break:
            LiquidGlass.warningTint.opacity(0.5)
        case .longBreak:
            LiquidGlass.warningTint.opacity(0.6)
        }
    }
}

#Preview {
    CircularTimerView()
        .environment(PomodoroTimer())
}
