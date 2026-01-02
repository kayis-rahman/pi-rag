// Extracted from AnalyticsView.swift

import SwiftUI
import Charts

    let entries: [WeeklyEntry]
    let formatTime: (Int) -> String

    var body: some View {
        Chart(entries) { entry in
            BarMark(
                x: .value("Day", entry.weekday),
                y: .value("Minutes", entry.totalMinutes)
            )
            .foregroundStyle(entry.isToday ? Color.themeAccent : Color.themePrimary)
            .cornerRadius(4)
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine().foregroundStyle(Color.themeTextSecondary.opacity(0.1))
                AxisTick().foregroundStyle(Color.themeTextSecondary.opacity(0.3))
                AxisValueLabel {
                    if let minutes = value.as(Int.self) {
                        Text(formatTime(minutes))
                    }
                }
                .foregroundStyle(Color.themeTextSecondary)
            }
        }
    }
}
#endif
