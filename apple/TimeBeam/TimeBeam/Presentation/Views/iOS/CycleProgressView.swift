import SwiftUI

struct CycleProgressView: View {
    @ObservedObject var timer: PomodoroTimer

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<timer.cycleSize, id: \.self) { index in
                Circle()
                    .fill(index < timer.shortBreaksCompleted ? Color.themePrimary : Color.themeTextSecondary.opacity(0.3))
                    .frame(width: 10, height: 10)
            }
        }
    }
}
