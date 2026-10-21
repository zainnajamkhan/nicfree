//
//  Components.swift
//  NicFree
//

import SwiftUI

// MARK: - Label

/// Small, heavy, uppercase. Labels and data only, never sentences.
struct SectionLabel: View {
    private let text: LocalizedStringKey

    init(_ text: LocalizedStringKey) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(Typeface.label)
            .tracking(1.0)
            .textCase(.uppercase)
            .foregroundStyle(Palette.inkFaint)
    }
}

// MARK: - Buttons

/// A solid edge under the button that it presses down into.
private struct ChunkyStyle: ButtonStyle {
    let fill: Color
    let edge: Color
    let foreground: Color

    private let depth: CGFloat = 5

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        configuration.label
            .font(Typeface.button)
            .textCase(.uppercase)
            .tracking(0.4)
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 58)
            .background(fill, in: RoundedRectangle(cornerRadius: Radius.button))
            .offset(y: pressed ? depth - 1 : 0)
            .background(
                RoundedRectangle(cornerRadius: Radius.button)
                    .fill(edge)
                    .offset(y: depth)
            )
            .padding(.bottom, depth)
            .animation(.easeOut(duration: 0.08), value: pressed)
    }
}

struct PrimaryButton: View {
    private let title: LocalizedStringKey
    private let action: () -> Void

    init(_ title: LocalizedStringKey, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(action: action) { Text(title) }
            .buttonStyle(ChunkyStyle(fill: Palette.accent, edge: Palette.accentDeep, foreground: Palette.onAccent))
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
                .font(Typeface.row)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 50)
                .background(
                    RoundedRectangle(cornerRadius: Radius.button)
                        .stroke(Palette.hairline, lineWidth: 2)
                )
                .foregroundStyle(Palette.inkSoft)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Stat row

/// Label left, value right. Used in Settings-style lists.
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

// MARK: - Stat chip

/// A rounded pill with an icon and one number. Home shows three of them.
struct StatChip: View {
    let symbol: String
    let value: String
    let fill: Color
    let tint: Color
    let ink: Color
    let label: LocalizedStringKey

    var body: some View {
        HStack(spacing: Space.xs + 2) {
            Image(systemName: symbol)
                .font(.callout.weight(.bold))
                .foregroundStyle(tint)
            Text(value)
                .font(Typeface.chip)
                .foregroundStyle(ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, minHeight: 40)
        .background(fill, in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(value)
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
                .font(Typeface.row)
                .padding(.horizontal, Space.m * 0.9)
                .padding(.vertical, Space.s + 2)
                .background(
                    Group {
                        if isOn {
                            Capsule().fill(Palette.accentQuiet)
                                .overlay(Capsule().stroke(Palette.leaf, lineWidth: 2))
                        } else {
                            Capsule().stroke(Palette.hairline, lineWidth: 2)
                        }
                    }
                )
                .foregroundStyle(isOn ? Palette.ink : Palette.inkSoft)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? [.isSelected] : [])
    }
}

// MARK: - Onboarding progress

/// Onboarding progress as a row of rounded bars. The name is kept from the earlier
/// design so the call site does not move.
struct StoneProgress: View {
    let total: Int
    let current: Int

    var body: some View {
        HStack(spacing: Space.xs + 2) {
            ForEach(0..<total, id: \.self) { index in
                Capsule()
                    .fill(index <= current ? Palette.leaf : Palette.hairline)
                    .frame(height: 10)
                    .animation(.smooth(duration: 0.35), value: current)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Step \(current + 1) of \(total)")
    }
}

// MARK: - Pinned actions

/// Content that scrolls above buttons that never move. Centred vertically when it fits,
/// scrollable when it does not, so at the largest text sizes nothing is pushed off screen.
struct PinnedActions<Content: View, Actions: View>: View {
    var ground: Color = Palette.ground
    @ViewBuilder var content: Content
    @ViewBuilder var actions: Actions

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                content
                    .frame(maxWidth: .infinity, minHeight: proxy.size.height, alignment: .leading)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            actions
                .padding(.vertical, Space.s)
                .background(ground)
        }
    }
}

// MARK: - Screen scaffold

/// Every screen sits on the same ground with the same margins. The craving screen passes
/// its own calmer ground.
struct Screen<Content: View>: View {
    var ground: Color = Palette.ground
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            ground.ignoresSafeArea()
            content
                .padding(.horizontal, Space.l)
        }
        .tint(Palette.accent)
    }
}
