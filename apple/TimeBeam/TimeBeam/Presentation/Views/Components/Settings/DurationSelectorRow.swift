// Extracted from SettingsComponents.swift

import SwiftUI

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color.themeTextPrimary)

            HStack(spacing: 16) {
                Button(action: { value = max(range.lowerBound, value - step) }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(value > range.lowerBound ? Color.themeAccent : Color.themeTextSecondary.opacity(0.3))
                }
                .disabled(value <= range.lowerBound)

                Spacer()

                Text("\(value) \(unit)")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.themeTextPrimary)
                    .frame(minWidth: 80)

                Spacer()

                Button(action: { value = min(range.upperBound, value + step) }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(value < range.upperBound ? Color.themeAccent : Color.themeTextSecondary.opacity(0.3))
                }
                .disabled(value >= range.upperBound)
            }
        }
        .padding(.vertical, 8)
    }
}

struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(Color.themeTextSecondary)
            .textCase(.uppercase)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
    }
}

#Preview {
    VStack(spacing: 24) {
        SectionHeader(title: "Timer Settings")
