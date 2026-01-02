// Extracted from SettingsComponents.swift

import SwiftUI

import SwiftUI

struct ToggleRow: View {
    let title: String
    let subtitle: String?
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color.themeTextPrimary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(Color.themeTextSecondary)
                }
            }
        }
        .tint(Color.themePrimary)
        .padding(.vertical, 8)
    }
}

struct DurationSelectorRow: View {
    let title: String
    let range: ClosedRange<Int>
    let step: Int
    let unit: String
    @Binding var value: Int
