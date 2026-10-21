//
//  Theme.swift
//  Cairn
//

import SwiftUI
import UIKit

// MARK: - Palette

/// Sprout: bright, rounded and friendly, built around one green.
///
/// Both themes are authored, not derived. The dark ground is a deep green black rather
/// than an inverted white, so the greens still read as living things on either.
///
/// Names from the earlier calm palette are kept so every screen restyles from here.
/// `clay` stays the colour of a used day, and it is never red: red is alarm, and alarm
/// is shame.
enum Palette {
    static let ground = Color(light: 0xFFFFFF, dark: 0x111815)
    static let surface = Color(light: 0xF3F6F4, dark: 0x1A2420)
    static let sunk = Color(light: 0xE5E8EB, dark: 0x0C110F)

    static let ink = Color(light: 0x2B2F33, dark: 0xEEF2EC)
    static let inkSoft = Color(light: 0x5F6870, dark: 0xA5B0A8)
    static let inkFaint = Color(light: 0x66707A, dark: 0x8B968E)

    static let hairline = Color(light: 0xE5E8EB, dark: 0x2A352F)

    /// Buttons and the free-day circles.
    static let accent = Color(light: 0x2E7D32, dark: 0x5DB761)
    /// The solid edge under a chunky button.
    static let accentDeep = Color(light: 0x1B5E20, dark: 0x2E7D32)
    /// Text on top of `accent`.
    static let onAccent = Color(light: 0xFFFFFF, dark: 0x0C110F)
    static let accentQuiet = Color(light: 0xE9F5EA, dark: 0x24382A)
    static let leaf = Color(light: 0x4CAF50, dark: 0x5DB761)

    /// Used days. Never red.
    static let clay = Color(light: 0xB98A6E, dark: 0xB98A6E)
    static let clayQuiet = Color(light: 0xE7D3C6, dark: 0x4A3A34)

    /// Cravings beaten.
    static let sky = Color(light: 0x1769AA, dark: 0x6FB8E8)
    static let skyInk = Color(light: 0x11507F, dark: 0xBFE2F8)
    static let skyQuiet = Color(light: 0xE6F3FC, dark: 0x1B3040)
    /// The craving screen ground, calmer than the rest of the app.
    static let calm = Color(light: 0xEAF6FD, dark: 0x0F1C26)
    static let calmRing = Color(light: 0xCDEBFB, dark: 0x183044)
    static let calmRingDeep = Color(light: 0xA9DCF8, dark: 0x1F4560)

    /// Money not spent.
    static let sun = Color(light: 0xE8A800, dark: 0xF2C14B)
    static let sunInk = Color(light: 0x7A5600, dark: 0xFBE3A0)
    static let sunQuiet = Color(light: 0xFFF4D6, dark: 0x3A3118)

    /// The mascot's pot.
    static let pot = Color(light: 0xF0A04B, dark: 0xE09342)
    static let potRim = Color(light: 0xD9822B, dark: 0xC47A2E)
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

/// Rounded system type throughout. It keeps Dynamic Type for free and gives the
/// friendly feel without shipping a font.
enum Typeface {
    static func hero(_ size: CGFloat) -> Font {
        .system(size: size, weight: .heavy, design: .rounded).monospacedDigit()
    }

    static let title = Font.system(.title, design: .rounded, weight: .heavy)
    static let voice = Font.system(.title3, design: .rounded, weight: .bold)
    static let voiceSmall = Font.system(.subheadline, design: .rounded, weight: .semibold)
    static let row = Font.system(.subheadline, design: .rounded, weight: .semibold)
    static let label = Font.system(.caption, design: .rounded, weight: .heavy)
    static let chip = Font.system(.callout, design: .rounded, weight: .heavy).monospacedDigit()
    static let button = Font.system(.headline, design: .rounded, weight: .heavy)
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
    static let card: CGFloat = 24
    static let chip: CGFloat = 999
    static let stone: CGFloat = 3
}
