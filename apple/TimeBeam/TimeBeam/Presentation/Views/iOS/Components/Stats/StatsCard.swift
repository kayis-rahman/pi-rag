// Extracted from StatsView.swift

import SwiftUI

}

struct SessionRow: View {
    let session: SessionRecord

    var body: some View {
        HStack(spacing: 12) {
            // Phase indicator
            Circle()
                .fill(phaseColor)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(session.kind.displayName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.themeTextPrimary)

                Text(formatDuration(Int(session.duration / 60)))
                    .font(.system(size: 12))
                    .foregroundColor(Color.themeTextSecondary)
            }

            Spacer()

            Text(formatTime(session.startedAt))
                .font(.system(size: 12))
                .foregroundColor(Color.themeTextSecondary)
        }
        .padding(.vertical, 8)
    }

    private var phaseColor: Color {
        switch session.kind {
        case .work: return Color.themePrimary
        case .shortBreak: return Color.themeOrangeAccent
        case .longBreak: return Color.themeOrangeDeep