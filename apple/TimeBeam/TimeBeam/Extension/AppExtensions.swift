//
//  PomodoroTimer.swift
//  TimeBeam
//
//  Created by Kayis Rahman on 03/11/25.
//

import SwiftUI

// MARK: - Theming Colors
extension Color {
    // Define your app's theme colors here. These are placeholders.
    static let themeBackground = Color(nsColor: .windowBackgroundColor)
    static let themePrimary = Color.accentColor
    static let themeSecondary = Color.green
    static let themeTextPrimary = Color(nsColor: .textColor)
    static let themeTextSecondary = Color(nsColor: .secondaryLabelColor)
    static let themeAccent = Color.white
}

// MARK: - Gradient Extension
extension AngularGradient {
    static func forThemePhase(_ phase: Phase) -> AngularGradient {
        let colors: [Color]
        switch phase {
        case .work:
            colors = [.themePrimary, .themePrimary.opacity(0.6)]
        case .break, .longBreak:
            colors = [.themeSecondary, .themeSecondary.opacity(0.6)]
        }
        return AngularGradient(gradient: Gradient(colors: colors), center: .center)
    }
}


// MARK: - Int Extension
extension Int {
    var mmss: String {
        let minutes = self / 60
        let seconds = self % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
