import SwiftUI
import Charts

// Extracted from AnalyticsView.swift

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
private struct ChartsWeeklyBars: View {