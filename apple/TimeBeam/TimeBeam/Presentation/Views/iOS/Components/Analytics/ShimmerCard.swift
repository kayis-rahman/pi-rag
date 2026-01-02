// Extracted from AnalyticsView.swift

import SwiftUI
import Charts

private struct ShimmerCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.themeCardBackground.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.themeTextSecondary.opacity(0.1), lineWidth: 1)
        )
    }
}
