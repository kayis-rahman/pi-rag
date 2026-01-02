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

        DurationSelectorRow(
            title: "Focus Duration",
            range: 15...60,
            step: 5,
            unit: "min",
            value: .constant(25)
        )

        ToggleRow(
            title: "Auto-start next session",
            subtitle: "Automatically begin the next timer when one completes",
            isOn: .constant(true)
        )

        ToggleRow(
            title: "Sound & Haptics",
            subtitle: nil,
            isOn: .constant(false)
        )
    }
    .padding()
    .background(Color.themeBackground)
}
