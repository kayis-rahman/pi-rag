import SwiftUI

struct CircularTimerView: View {
    @EnvironmentObject var timer: PomodoroTimer

    let size: CGFloat
    let showSessionProgress: Bool

    init(size: CGFloat = 280, showSessionProgress: Bool = true) {
        self.size = size
        self.showSessionProgress = showSessionProgress
    }

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.themeTextSecondary.opacity(0.2), lineWidth: size * 0.04)
                .frame(width: size, height: size)

            // Progress circle
            Circle()
                .trim(from: 0, to: timer.progress)
                .stroke(
                    AngularGradient.forThemePhase(timer.phase),
                    style: StrokeStyle(
                        lineWidth: size * 0.04,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .frame(width: size, height: size)
                .shadow(color: Color.themePrimary.opacity(0.3), radius: 8, x: 0, y: 0)

            // Pulsing animation when active
            if timer.isRunning {
                Circle()
                    .stroke(Color.themePrimary.opacity(0.3), lineWidth: size * 0.04)
                    .frame(width: size, height: size)
                    .scaleEffect(1.05)
                    .opacity(0.6)
                    .animation(
                        .easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true),
                        value: timer.isRunning
                    )
            }

            // Content overlay
            VStack(spacing: size * 0.02) {
                // Time display
                Text(timer.remainingSeconds.mmss)
                    .font(.system(size: size * 0.18, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(Color.themeTextPrimary)

                // Phase label
                Text(timer.phase.displayName)
                    .font(.system(size: size * 0.06, weight: .medium, design: .rounded))
                    .foregroundColor(Color.themeTextSecondary)

                // Session progress (only show if requested)
                if showSessionProgress {
                    Text("Cycle \(timer.shortBreaksCompleted + 1) of \(timer.cycleSize)")
                        .font(.system(size: size * 0.04, weight: .regular, design: .rounded))
                        .foregroundColor(Color.themeTextSecondary.opacity(0.7))
                        .padding(.top, size * 0.02)
                }
            }
        }
        .frame(width: size, height: size)
    }
}

// Phase display names are defined in Phase.swift

// Angular gradient extension
extension AngularGradient {
    static func forThemePhase(_ phase: Phase) -> AngularGradient {
        switch phase {
        case .work:
            return AngularGradient(
                gradient: Gradient(colors: [Color.themePrimary, Color.themeAccent]),
                center: .center,
                startAngle: .degrees(0),
                endAngle: .degrees(360)
            )
        case .break:
            return AngularGradient(
                gradient: Gradient(colors: [Color.themeOrangePrimary, Color.themeOrangeAccent]),
                center: .center,
                startAngle: .degrees(0),
                endAngle: .degrees(360)
            )
        case .longBreak:
            return AngularGradient(
                gradient: Gradient(colors: [Color.themeOrangeAccent, Color.themeOrangeDeep]),
                center: .center,
                startAngle: .degrees(0),
                endAngle: .degrees(360)
            )
        }
    }
}

#Preview {
    CircularTimerView()
        .environmentObject(PomodoroTimer())
}
