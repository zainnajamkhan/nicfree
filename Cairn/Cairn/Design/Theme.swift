//
//  Theme.swift
//  Cairn
//

import SwiftUI
import UIKit

// MARK: - Palette

/// Wet slate, lichen and weathered clay, taken from the object the app is named after.
///
/// Both themes are authored, not derived. The dark ground is a cold blue grey and the
/// light ground a pale cool granite, so the single green accent reads as chosen rather
/// than decorative on either.
enum Palette {
    static let ground = Color(light: 0xEDEEE9, dark: 0x12171A)
    static let surface = Color(light: 0xF7F7F3, dark: 0x191F23)
    static let sunk = Color(light: 0xE3E5DE, dark: 0x0D1114)

    static let ink = Color(light: 0x1C2226, dark: 0xE4E2DA)
    static let inkSoft = Color(light: 0x59636A, dark: 0x949D9F)
    static let inkFaint = Color(light: 0x8B948B, dark: 0x6B747A)

    static let hairline = Color(light: 0xD5D8D0, dark: 0x262D32)

    static let accent = Color(light: 0x57755C, dark: 0x8FA98F)
    static let accentQuiet = Color(light: 0xA8BCA9, dark: 0x3C4B3E)

    /// Used days. Never red: red is alarm, and alarm is shame.
    static let clay = Color(light: 0x8A6C60, dark: 0xA8887A)
    static let clayQuiet = Color(light: 0xC7B0A5, dark: 0x4A3A34)
}

extension Color {
    /// Resolved per trait collection so neither theme is an inversion of the other.
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            UIColor(rgb: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

private extension UIColor {
    convenience init(rgb: UInt32) {
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255,
            alpha: 1
        )
    }
}

// MARK: - Type

/// Three roles and no more. The serif carries anything that should sound like a person
/// talking, which is the copy that matters most: their reasons, and the line after a slip.
enum Typeface {
    /// The only large element in the app.
    static func hero(_ size: CGFloat) -> Font {
        .system(size: size, weight: .medium).monospacedDigit()
    }

    static let voice = Font.system(.title3, design: .serif)
    static let voiceSmall = Font.system(.subheadline, design: .serif)
    static let row = Font.subheadline
    static let label = Font.system(.caption2, design: .monospaced)
}

// MARK: - Spacing

enum Space {
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 16
    static let l: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

enum Radius {
    static let button: CGFloat = 16
    static let chip: CGFloat = 999
    static let stone: CGFloat = 3
}
