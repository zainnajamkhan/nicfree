//
//  LivingSprout.swift
//  NicFree
//

import SwiftUI

/// The sprout on Home, as a pet: tap it and it wiggles and rustles. When it reaches a new
/// stage, the next time Home opens it grows into it on screen, with a swelling haptic that
/// pops as the new leaf, bud or flower opens.
///
/// Fed **finished** free days, so a slip today never takes anything away from it.
struct LivingSprout: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let finishedDays: Int
    let thirsty: Bool
    /// The last stage already shown growing. Nil until the first look, which only records it.
    let seenStage: Int?
    let onSeenStage: (Int) -> Void

    @State private var shownDays: Double?
    @State private var pets = 0

    var body: some View {
        Sprout(days: shownDays ?? Double(finishedDays), thirsty: thirsty)
            .keyframeAnimator(initialValue: Pose(), trigger: pets) { content, pose in
                content
                    .rotationEffect(.degrees(pose.angle), anchor: .bottom)
                    .scaleEffect(x: pose.stretch, y: 1 / pose.stretch, anchor: .bottom)
            } keyframes: { _ in
                KeyframeTrack(\.angle) {
                    SpringKeyframe(thirsty ? -3 : -9, duration: 0.12)
                    SpringKeyframe(thirsty ? 2 : 7, duration: 0.14)
                    SpringKeyframe(thirsty ? -1 : -4, duration: 0.14)
                    SpringKeyframe(0, duration: 0.25)
                }
                KeyframeTrack(\.stretch) {
                    SpringKeyframe(thirsty ? 1.02 : 1.08, duration: 0.1)
                    SpringKeyframe(0.96, duration: 0.15)
                    SpringKeyframe(1, duration: 0.3)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { pet() }
            .accessibilityAddTraits(.isButton)
            .accessibilityHint("Pet your sprout")
            .accessibilityAction { pet() }
            .task(id: finishedDays) { await growIfNeeded() }
    }

    private struct Pose {
        var angle: Double = 0
        var stretch: CGFloat = 1
    }

    private func pet() {
        if !reduceMotion { pets += 1 }
        thirsty ? SproutHaptics.thirstyPet() : SproutHaptics.pet()
    }

    /// A new stage plays once: from just before it, up to today.
    private func growIfNeeded() async {
        let current = Sprout.stageIndex(freeDays: finishedDays)
        guard let seen = seenStage else {
            onSeenStage(current)
            return
        }
        guard current > seen else {
            shownDays = nil
            return
        }
        onSeenStage(current)
        guard !reduceMotion else {
            SproutHaptics.pop()
            return
        }

        shownDays = Double(Sprout.stages[current].day - 1)
        try? await Task.sleep(for: .milliseconds(700))
        SproutHaptics.grow(duration: 0.9)
        withAnimation(.easeIn(duration: 0.9)) { shownDays = Double(Sprout.stages[current].day) - 0.05 }
        try? await Task.sleep(for: .milliseconds(900))
        withAnimation(.spring(duration: 0.6, bounce: 0.5)) { shownDays = Double(finishedDays) }
        pets += 1
    }
}
