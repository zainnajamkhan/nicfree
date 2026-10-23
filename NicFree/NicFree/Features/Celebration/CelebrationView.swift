//
//  CelebrationView.swift
//  NicFree
//

import SwiftUI
import UIKit

/// One or more finished free days, ready to be celebrated.
struct CelebrationMoment: Identifiable {
    let id = UUID()
    /// The total before these days, which the number counts up from.
    let from: Int
    let to: Int
    /// The biggest milestone passed, which gets the bigger version.
    let milestone: Int?

    var gained: Int { to - from }
}

/// Shown on Home after a free day finishes: the sprout pops in, leaves burst out of it, and
/// the total ticks up. Only ever for a free day, so it can't land on a hard one.
///
/// Under Reduce Motion there's no burst, bounce or count, just the finished screen.
struct CelebrationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let moment: CelebrationMoment

    @State private var shown: Int
    @State private var popped = false
    @State private var burstStart: Date?

    init(moment: CelebrationMoment) {
        self.moment = moment
        _shown = State(initialValue: moment.from)
    }

    var body: some View {
        ZStack {
            Palette.ground.ignoresSafeArea()

            Screen {
                PinnedActions {
                    VStack(spacing: Space.l) {
                        Spacer(minLength: Space.xl)
                        sprout
                        VStack(spacing: Space.s) {
                            Text(shown.formatted())
                                .font(Typeface.hero(88))
                                .foregroundStyle(Palette.accent)
                                .contentTransition(.numericText(value: Double(shown)))
                                .monospacedDigit()
                            Text(headline)
                                .font(Typeface.title)
                                .foregroundStyle(Palette.ink)
                            Text(subline)
                                .font(Typeface.voice)
                                .foregroundStyle(Palette.inkSoft)
                        }
                        .multilineTextAlignment(.center)
                        .accessibilityElement(children: .combine)
                        Spacer(minLength: Space.l)
                    }
                    .frame(maxWidth: .infinity)
                } actions: {
                    PrimaryButton("Yay!") { dismiss() }
                }
            }

            // On top, because `Screen` paints its own ground over anything beneath it.
            if let burstStart {
                LeafBurst(start: burstStart, count: moment.milestone == nil ? 40 : 80)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .task { await play() }
    }

    private var sprout: some View {
        ZStack {
            Circle()
                .fill(moment.milestone == nil ? Palette.accentQuiet : Palette.sunQuiet)
                .frame(width: 200, height: 200)
                .scaleEffect(popped ? 1 : 0.5)
            Sprout(freeDays: shown)
                .frame(width: 150, height: 150)
                .scaleEffect(popped ? 1 : 0.3)
                .rotationEffect(.degrees(popped ? 0 : -14))
        }
        .opacity(popped ? 1 : 0)
        .accessibilityHidden(true)
    }

    private var headline: String {
        if let milestone = moment.milestone {
            return MilestoneScheduler.title(for: milestone)
        }
        return moment.gained == 1
            ? String(localized: "Another free day!")
            : String(inflecting: "^[\(moment.gained) more free day](inflect: true)!")
    }

    /// A few friendly lines, picked by the total so the same day always says the same thing.
    private var subline: String {
        let lines = [
            String(localized: "Your sprout is growing."),
            String(localized: "Look at you go!"),
            String(localized: "One day at a time."),
            String(localized: "Your sprout is proud of you."),
            String(localized: "That’s one more for the total."),
        ]
        return lines[moment.to % lines.count]
    }

    private func play() async {
        guard !reduceMotion else {
            popped = true
            shown = moment.to
            return
        }
        try? await Task.sleep(for: .milliseconds(150))
        withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) { popped = true }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        burstStart = Date()
        try? await Task.sleep(for: .milliseconds(450))
        withAnimation(.smooth(duration: 0.6)) { shown = moment.to }
    }
}

/// Leaves and dots thrown up from the sprout, falling back down and fading out.
private struct LeafBurst: View {
    let start: Date
    @State private var pieces: [Piece]

    private static let lifetime = 2.8

    init(start: Date, count: Int) {
        self.start = start
        _pieces = State(initialValue: (0..<count).map { _ in Piece.random() })
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSince(start)
                guard t < Self.lifetime else { return }
                // Thrown from where the sprout sits on screen.
                let origin = CGPoint(x: size.width / 2, y: size.height * 0.3)
                let gravity = 900.0

                for piece in pieces {
                    let age = t - piece.delay
                    guard age > 0 else { continue }
                    let x = origin.x + piece.velocity.dx * age
                    let y = origin.y + piece.velocity.dy * age + 0.5 * gravity * age * age
                    let fade = max(0, min(1, (Self.lifetime - t) / 0.8))

                    var layer = context
                    layer.opacity = fade
                    layer.translateBy(x: x, y: y)
                    layer.rotate(by: .radians(piece.spin * age + piece.angle))
                    layer.fill(piece.shape, with: .color(piece.color))
                }
            }
        }
    }

    private struct Piece {
        let velocity: CGVector
        let delay: Double
        let angle: Double
        let spin: Double
        let shape: Path
        let color: Color

        static func random() -> Piece {
            let direction = Double.random(in: -Double.pi * 0.95 ... -Double.pi * 0.05)
            let speed = Double.random(in: 380...820)
            let size = Double.random(in: 9...16)
            let isLeaf = Double.random(in: 0...1) < 0.7
            let shape = isLeaf
                ? Path(ellipseIn: CGRect(x: -size * 0.3, y: -size / 2, width: size * 0.6, height: size))
                : Path(ellipseIn: CGRect(x: -size / 4, y: -size / 4, width: size / 2, height: size / 2))
            return Piece(
                velocity: CGVector(dx: cos(direction) * speed, dy: sin(direction) * speed),
                delay: Double.random(in: 0...0.15),
                angle: Double.random(in: 0...(2 * .pi)),
                spin: Double.random(in: -8...8),
                shape: shape,
                color: [Palette.leaf, Palette.accent, Palette.sun, Palette.sky, Palette.leaf].randomElement() ?? Palette.leaf
            )
        }
    }
}

#Preview("A free day") {
    CelebrationView(moment: CelebrationMoment(from: 12, to: 13, milestone: nil))
}

#Preview("A milestone") {
    CelebrationView(moment: CelebrationMoment(from: 6, to: 7, milestone: 7))
}
