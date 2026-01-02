// Extracted from AnalyticsView.swift

import SwiftUI
import Charts

    let systemName: String
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.17))
                .frame(width: 32, height: 32)
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
        }
        .frame(width: 32, height: 32)
    }
}