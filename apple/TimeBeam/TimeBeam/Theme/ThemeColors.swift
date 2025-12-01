import SwiftUI

extension Color {
    // Primary Green Scheme
    static let themePrimary = Color(hex: "#A8E6CF")
    static let themeSecondary = Color(hex: "#FFD7A8") // Orange secondary
    static let themeAccent = Color(hex: "#56C596")
    static let themeTextPrimary = Color(hex: "#1B4332")
    static let themeBackground = Color(hex: "#F7FDFB")

    // Alternative Warm Orange Scheme (can be toggled)
    static let themeOrangePrimary = Color(hex: "#FFD7A8")
    static let themeOrangeAccent = Color(hex: "#FF9F1C")
    static let themeOrangeDeep = Color(hex: "#D2691E")
    static let themeOrangeBackground = Color(hex: "#FFF8ED")

    // Neutral colors
    static let themeTextSecondary = Color.gray.opacity(0.8)
    static let themeBorder = Color.gray.opacity(0.2)
    static let themeCardBackground = Color.white.opacity(0.8)

    // Semantic colors
    static let themeSuccess = Color.green.opacity(0.8)
    static let themeWarning = Color.orange.opacity(0.8)
    static let themeError = Color.red.opacity(0.8)
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
