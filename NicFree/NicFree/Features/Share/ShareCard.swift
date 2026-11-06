//
//  ShareCard.swift
//  NicFree
//

import SwiftUI

/// What gets shared: a milestone, or the total so far.
struct ShareMoment: Identifiable {
    let id = UUID()
    /// The number on the card.
    let days: Int
    /// Days the sprout is drawn at, so it matches the plant on Home.
    let sproutDays: Int
    /// Set for a milestone, which gets its title as the headline.
    let milestone: Int?
}

/// A 4:5 graphic made to be posted or sent: the sprout, the number, and the app's name.
///
/// Not a social feature. Nothing is posted by the app; it hands an image to the share sheet
/// and the person decides where it goes. Always drawn in the light palette, so it looks the
/// same wherever it lands.
struct ShareCard: View {
    let moment: ShareMoment

    static let size = CGSize(width: 360, height: 450)

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Palette.sunQuiet, Palette.accentQuiet],
                startPoint: .top,
                endPoint: .bottom
            )

            // Soft hills, the same green as the year grid's free days.
            Ellipse()
                .fill(Palette.leaf.opacity(0.18))
                .frame(width: 560, height: 220)
                .offset(y: 230)
            Ellipse()
                .fill(Palette.leaf.opacity(0.14))
                .frame(width: 420, height: 180)
                .offset(x: 140, y: 250)

            VStack(spacing: 0) {
                HStack(spacing: 6) {
                    Image(systemName: "leaf.fill")
                        .foregroundStyle(Palette.accent)
                    Text(verbatim: "NicFree")
                        .foregroundStyle(Palette.ink)
                }
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .padding(.top, 26)

                Spacer(minLength: 8)

                ZStack {
                    Circle()
                        .fill(RadialGradient(
                            colors: [Color.white.opacity(0.9), Color.white.opacity(0)],
                            center: .center, startRadius: 10, endRadius: 110
                        ))
                        .frame(width: 220, height: 220)
                    Sprout(freeDays: moment.sproutDays)
                        .frame(width: 170, height: 170)
                }

                Text(moment.days.formatted())
                    .font(.system(size: 76, weight: .black, design: .rounded))
                    .foregroundStyle(Palette.accent)
                    .monospacedDigit()
                    .padding(.top, 2)
                Text(moment.days == 1 ? String(localized: "day nicotine-free") : String(localized: "days nicotine-free"))
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(Palette.ink)

                if let milestone = moment.milestone {
                    Text(MilestoneScheduler.title(for: milestone))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Palette.sunInk)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Palette.sunQuiet, in: Capsule())
                        .overlay(Capsule().strokeBorder(Palette.sun.opacity(0.5), lineWidth: 1.5))
                        .padding(.top, 10)
                }

                Spacer(minLength: 8)

                Text("Growing with NicFree")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.inkSoft)
                    .padding(.bottom, 22)
            }
            .multilineTextAlignment(.center)
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .environment(\.colorScheme, .light)
    }

    /// 1080 by 1350 pixels, the portrait size every major app accepts.
    @MainActor
    static func render(_ moment: ShareMoment) -> UIImage? {
        let renderer = ImageRenderer(content: ShareCard(moment: moment))
        renderer.scale = 3
        return renderer.uiImage
    }
}

/// The card, large, with one button to the share sheet.
struct ShareCardSheet: View {
    @Environment(\.dismiss) private var dismiss
    let moment: ShareMoment

    @State private var image: Image?

    var body: some View {
        Screen {
            PinnedActions {
                VStack(spacing: Space.l) {
                    ShareCard(moment: moment)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.card))
                        .shadow(color: Palette.ink.opacity(0.15), radius: 20, y: 10)
                        .scaleEffect(0.9)
                        .accessibilityElement(children: .combine)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, Space.l)
            } actions: {
                VStack(spacing: Space.s) {
                    if let image {
                        ShareLink(
                            item: image,
                            preview: SharePreview(String(localized: "My NicFree sprout"), image: image)
                        ) {
                            Text("Share")
                        }
                        .buttonStyle(ShareButtonStyle())
                    }
                    SecondaryButton("Close") { dismiss() }
                }
            }
        }
        .task {
            if let rendered = ShareCard.render(moment) { image = Image(uiImage: rendered) }
        }
    }
}

/// The primary button's look, for a `ShareLink`, which can't be a `PrimaryButton`.
private struct ShareButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        configuration.label
            .font(Typeface.button)
            .textCase(.uppercase)
            .tracking(0.4)
            .foregroundStyle(Palette.onAccent)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 58)
            .background(Palette.accent, in: RoundedRectangle(cornerRadius: Radius.button))
            .offset(y: pressed ? 4 : 0)
            .background(
                RoundedRectangle(cornerRadius: Radius.button)
                    .fill(Palette.accentDeep)
                    .offset(y: 5)
            )
            .padding(.bottom, 5)
    }
}

#Preview {
    ShareCard(moment: ShareMoment(days: 30, sproutDays: 30, milestone: 30))
}
