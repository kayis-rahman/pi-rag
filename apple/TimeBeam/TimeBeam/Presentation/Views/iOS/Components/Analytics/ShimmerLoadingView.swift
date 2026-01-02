import SwiftUI
import Charts

// Extracted from AnalyticsView.swift

struct ShimmerLoadingView: View {
    @State private var isAnimating = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header card skeleton
                ShimmerCard {
                    HStack(spacing: 16) {
                        // Activity ring placeholder
                        Circle()
                            .fill(Color.themeTextSecondary.opacity(0.1))
                            .frame(width: 60, height: 60)

                        VStack(alignment: .leading, spacing: 6) {
                            // Title placeholder
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.themeTextSecondary.opacity(0.1))
                                .frame(width: 120, height: 16)
