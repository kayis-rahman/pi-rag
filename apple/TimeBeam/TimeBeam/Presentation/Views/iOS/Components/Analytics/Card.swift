// Extracted from AnalyticsView.swift

import SwiftUI
import Charts

private struct Card<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding(16)
        .background(backgroundStyle)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.themeTextSecondary.opacity(0.16), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var backgroundStyle: some View {
        let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
        #if os(watchOS)
        if #available(watchOS 10.0, *) {
            shape.fill(.regularMaterial)
        } else {
            shape.fill(Color.themeBackground.opacity(0.6))
        }
        #else
        shape.fill(.regularMaterial)
        #endif
    }
}
