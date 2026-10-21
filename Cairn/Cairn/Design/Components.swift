//
//  Components.swift
//  Cairn
//

import SwiftUI

// MARK: - Label

/// Monospaced, uppercase, widely tracked. Labels and data only, never sentences.
struct SectionLabel: View {
    private let text: LocalizedStringKey

    init(_ text: LocalizedStringKey) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(Typeface.label)
            .tracking(1.6)
            .textCase(.uppercase)
            .foregroundStyle(Palette.inkFaint)
    }
}

// MARK: - Buttons

struct PrimaryButton: View {
    private let title: LocalizedStringKey
    private let action: () -> Void

    init(_ title: LocalizedStringKey, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Space.m)
                .background(Palette.accent, in: RoundedRectangle(cornerRadius: Radius.button))
                .foregroundStyle(Palette.sunk)
        }
        .buttonStyle(.plain)
    }
}

struct SecondaryButton: View {
    private let title: LocalizedStringKey
    private let action: () -> Void

    init(_ title: LocalizedStringKey, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Space.m)
                .background(
                    RoundedRectangle(cornerRadius: Radius.button)
                        .stroke(Palette.hairline, lineWidth: 1)
                )
                .foregroundStyle(Palette.inkSoft)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Stat row

/// Hairline above, label left, value right. Never competes with the hero.
struct StatRow: View {
    private let title: LocalizedStringKey
    private let value: String

    init(_ title: LocalizedStringKey, value: String) {
        self.title = title
        self.value = value
    }

    var body: some View {
        VStack(spacing: 0) {
            Divider().overlay(Palette.hairline)
            HStack {
                Text(title).foregroundStyle(Palette.inkSoft)
                Spacer()
                Text(value).monospacedDigit().foregroundStyle(Palette.ink)
            }
            .font(Typeface.row)
            .padding(.vertical, Space.m * 0.7)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Chip

struct Chip: View {
    private let title: String
    private let isOn: Bool
    private let action: () -> Void

    init(_ title: String, isOn: Bool, action: @escaping () -> Void) {
        self.title = title
        self.isOn = isOn
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, Space.m * 0.8)
                .padding(.vertical, Space.s)
                .background(
                    Group {
                        if isOn {
                            Capsule().fill(Palette.accentQuiet)
                        } else {
                            Capsule().stroke(Palette.hairline, lineWidth: 1)
                        }
                    }
                )
                .foregroundStyle(isOn ? Palette.ink : Palette.inkSoft)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? [.isSelected] : [])
    }
}

// MARK: - Stone progress

/// Onboarding progress as a stack of stones rather than dots, because that is the object
/// the app is named after and it is the one place a motif earns its keep.
struct StoneProgress: View {
    let total: Int
    let current: Int

    var body: some View {
        HStack(spacing: Space.xs + 2) {
            ForEach(0..<total, id: \.self) { index in
                RoundedRectangle(cornerRadius: Radius.stone)
                    .fill(index <= current ? Palette.accentQuiet : Palette.hairline)
                    .frame(width: index == current ? 22 : 14, height: 5)
                    .animation(.smooth(duration: 0.35), value: current)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Step \(current + 1) of \(total)")
    }
}

// MARK: - Screen scaffold

/// Every screen sits on the ground colour with the same generous margins. One idea per
/// screen means the padding does as much work as the type.
struct Screen<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            Palette.ground.ignoresSafeArea()
            content
                .padding(.horizontal, Space.l)
        }
        .tint(Palette.accent)
    }
}
