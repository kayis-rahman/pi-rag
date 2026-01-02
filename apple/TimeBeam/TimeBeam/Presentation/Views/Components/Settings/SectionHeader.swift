// Extracted from SettingsComponents.swift

import SwiftUI

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