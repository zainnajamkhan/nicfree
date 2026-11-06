//
//  GrowingSprout.swift
//  NicFree
//

import SwiftUI

/// The sprout's whole life, played once at the end of onboarding: a seedling grows through
/// every stage to a golden plant in full bloom, with a pop of haptics at each one. It shows
/// what the free days are growing. Tap it to watch again.
///
/// Under Reduce Motion it just shows the finished plant.
struct GrowingSprout: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var days: Double = 0
    @State private var stage = 0
    @State private var playing = false
    @State private var task: Task<Void, Never>?

    var body: some View {
        VStack(spacing: Space.s) {
            Sprout(days: days)
                .frame(height: 200)

            VStack(spacing: 2) {
                Text(Sprout.stages[stage].name)
                    .font(.system(.title3, design: .rounded, weight: .heavy))
                    .foregroundStyle(Palette.ink)
                    .contentTransition(.opacity)
                Text(String(inflecting: "^[\(Sprout.stages[stage].day) free day](inflect: true)"))
                    .font(Typeface.row)
                    .foregroundStyle(Palette.inkSoft)
                    .monospacedDigit()
            }
            .animation(.smooth(duration: 0.25), value: stage)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { play() }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Plays the sprout growing again")
        .task { play() }
        .onDisappear { task?.cancel() }
    }

    private func play() {
        guard !playing else { return }
        guard !reduceMotion else {
            stage = Sprout.stages.count - 1
            days = Double(Sprout.stages[stage].day)
            return
        }
        task?.cancel()
        task = Task {
            playing = true
            defer { playing = false }
            stage = 0
            days = 0
            try? await Task.sleep(for: .milliseconds(500))
            for index in 1..<Sprout.stages.count {
                guard !Task.isCancelled else { return }
                stage = index
                // Quick, bouncy steps early on, easing into a slower, bigger last one.
                let last = index == Sprout.stages.count - 1
                SproutHaptics.grow(duration: last ? 0.5 : 0.25)
                withAnimation(.spring(duration: last ? 0.9 : 0.55, bounce: 0.4)) {
                    days = Double(Sprout.stages[index].day)
                }
                try? await Task.sleep(for: .milliseconds(last ? 1200 : 700))
            }
        }
    }
}

#Preview {
    GrowingSprout()
        .padding()
}
