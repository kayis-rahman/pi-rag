// Extracted from AnalyticsView.swift

import SwiftUI
import Charts

    let progress: Double
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.themeTextSecondary.opacity(0.2), lineWidth: size * 0.12)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Color.themePrimary,
                    style: StrokeStyle(lineWidth: size * 0.12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Weekly Bar Chart

struct WeeklyBarChartView: View {
    let entries: [WeeklyEntry]
    let formatTime: (Int) -> String

    var body: some View {
        #if canImport(Charts)
        if #available(iOS 16, macOS 13, watchOS 9, *) {
            ChartsWeeklyBars(entries: entries, formatTime: formatTime)
        } else {
            FallbackWeeklyBars(entries: entries, formatTime: formatTime)
        }
        #else
        FallbackWeeklyBars(entries: entries, formatTime: formatTime)
        #endif
    }
}

#if canImport(Charts)
@available(iOS 16, macOS 13, watchOS 9, *)