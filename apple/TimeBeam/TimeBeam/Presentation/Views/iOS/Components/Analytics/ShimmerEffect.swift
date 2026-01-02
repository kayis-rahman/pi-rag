// Extracted from AnalyticsView.swift

import SwiftUI
import Charts

    @Binding var isAnimating: Bool

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Shimmer overlay
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                .clear,
                                Color.white.opacity(0.1),
                                .clear
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * 0.8)
                    .offset(x: isAnimating ? geometry.size.width : -geometry.size.width)
                    .blendMode(.overlay)
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - IconBadge
