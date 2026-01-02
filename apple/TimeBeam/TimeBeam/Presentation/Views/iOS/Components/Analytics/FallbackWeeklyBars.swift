// Extracted from AnalyticsView.swift

import SwiftUI
import Charts

    let entries: [WeeklyEntry]
    let formatTime: (Int) -> String

    var body: some View {
        GeometryReader { geo in
            let maxVal = max(entries.map(\.totalMinutes).max() ?? 1, 1)
            let count = max(entries.count, 1)
            let slotWidth = geo.size.width / CGFloat(count)
            let barWidth = max(12, slotWidth * 0.7)

            HStack(alignment: .bottom, spacing: max(4, slotWidth * 0.3)) {
                ForEach(entries) { entry in
                    let h = CGFloat(entry.totalMinutes) / CGFloat(maxVal) * max(geo.size.height - 40, 1)
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(entry.isToday ? Color.themeAccent : Color.themePrimary)
                            .frame(width: barWidth, height: max(h, 2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(entry.isToday ? Color.themeAccent.opacity(0.5) : Color.clear, lineWidth: 2)
                            )

                        Text(entry.weekday)
                            .font(.caption2)
                            .foregroundStyle(Color.themeTextSecondary)
                            .frame(width: barWidth + 4)
                    }
                }
            }
        }