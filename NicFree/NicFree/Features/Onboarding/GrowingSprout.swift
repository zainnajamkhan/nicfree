//
//  GrowingSprout.swift
//  NicFree
//

import SwiftUI

/// The sprout's whole life as a slow time lapse, on the onboarding screen of its own: one
/// continuous growth from a seedling to a golden plant in full bloom, easing from stage to
/// stage with a moment's rest at each, while it sways a little as if in a breeze. Silent:
/// onboarding has no haptics. Tap it to watch again.
///
/// Drawn from the clock rather than from a chain of animations, so every leaf and flower
/// opens smoothly and the name beneath always matches what's on screen.
///
/// Under Reduce Motion it just shows the finished plant.
struct GrowingSprout: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Seconds from seedling to golden. Long enough to watch each part open.
    private static let duration: Double = 16

    @State private var start = Date()
    @State private var settled = false

    var body: some View {
        Group {
            if reduceMotion || settled {
                content(days: Double(Sprout.stages.last?.day ?? 365), time: 0)
            } else {
                TimelineView(.animation) { context in
                    let elapsed = context.date.timeIntervalSince(start)
                    content(days: Self.days(at: elapsed), time: elapsed)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { replay() }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Plays the sprout growing again")
        .task(id: start) {
            // Hold the finished plant once the time lapse is over.
            try? await Task.sleep(for: .seconds(Self.duration + 0.5))
            if !Task.isCancelled { settled = true }
        }
    }

    private func replay() {
        guard !reduceMotion else { return }
        settled = false
        start = Date()
    }

    private func content(days: Double, time: Double) -> some View {
        // The name changes once a stage is fully open, not while it's still unfolding.
        let stage = Sprout.stageIndex(freeDays: Int((days + 0.001).rounded(.down)))

        return VStack(spacing: Space.s) {
            Sprout(days: days)
                .frame(height: 240)
                // A slow sway from the pot, never more than a few degrees.
                .rotationEffect(.degrees(sin(time * 1.1) * 2.2), anchor: .bottom)

            VStack(spacing: 2) {
                Text(Sprout.stages[stage].name)
                    .font(.system(.title3, design: .rounded, weight: .heavy))
                    .foregroundStyle(Palette.ink)
                Text(String(inflecting: "^[\(Sprout.stages[stage].day) free day](inflect: true)"))
                    .font(Typeface.row)
                    .foregroundStyle(Palette.inkSoft)
                    .monospacedDigit()
            }
        }
    }

    /// The plant's age at a moment in the time lapse. Every stage gets an equal share of the
    /// time, in three parts: the plant fills out toward it, the new leaf or flower opens
    /// slowly, and then it rests, so each change can be seen before the next one starts.
    static func days(at elapsed: Double) -> Double {
        let stages = Sprout.stages
        let segments = Double(stages.count - 1)
        let position = min(max(elapsed / duration, 0), 1) * segments
        if position >= segments { return Double(stages[stages.count - 1].day) }

        let index = Int(position)
        let within = position - Double(index)
        let from = Double(stages[index].day)
        let to = Double(stages[index + 1].day)

        func smooth(_ x: Double) -> Double {
            let t = min(max(x, 0), 1)
            return t * t * (3 - 2 * t)
        }

        // A new part opens over the last day before its stage, so open is the one day
        // leading to `to`, and filling out is everything before that.
        if within < 0.25 { return from + (max(to - 1, from) - from) * smooth(within / 0.25) }
        if within < 0.8 { return max(to - 1, from) + (to - max(to - 1, from)) * smooth((within - 0.25) / 0.55) }
        return to
    }
}

#Preview {
    GrowingSprout()
        .padding()
}
