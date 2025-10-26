import SwiftUI

public extension Color {
    // Static colors that do not change with light/dark mode
    static let themePrimary   = Color(hex: "#E07A5F") // Terracotta
    static let themeAccent    = Color(hex: "#F4F1DE") // Sand Beige
    static let themeSecondary = Color(hex: "#81B29A") // Olive
}

public extension Color {
    // Dynamic colors that adapt to light/dark mode for iOS and macOS; watchOS uses a dark palette by default.
    #if os(iOS)
    static let themeBackground = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: "#2C1F18") : UIColor(hex: "#FAF8F5") })
    static let themeTextPrimary = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: "#F4F1DE") : UIColor(hex: "#272220") })
    static let themeTextSecondary = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: "#81B29A") : UIColor(hex: "#6C5E55") })
    #elseif os(macOS)
    static let themeBackground = Color(NSColor(name: nil, dynamicProvider: { $0.name == .darkAqua ? NSColor(hex: "#2C1F18") : NSColor(hex: "#FAF8F5") }))
    static let themeTextPrimary = Color(NSColor(name: nil, dynamicProvider: { $0.name == .darkAqua ? NSColor(hex: "#F4F1DE") : NSColor(hex: "#272220") }))
    static let themeTextSecondary = Color(NSColor(name: nil, dynamicProvider: { $0.name == .darkAqua ? NSColor(hex: "#81B29A") : NSColor(hex: "#6C5E55") }))
    #else
    // watchOS (and other platforms) fallback: dark palette
    static let themeBackground = Color(hex: "#2C1F18")
    static let themeTextPrimary = Color(hex: "#F4F1DE")
    static let themeTextSecondary = Color(hex: "#81B29A")
    #endif
}

public extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

#if os(iOS)
import UIKit

public extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}
#endif

#if os(macOS)
import AppKit

public extension NSColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}
#endif
