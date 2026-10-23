//
//  CravingView.swift
//  NicFree
//

import SwiftUI
import SwiftData

/// The four minutes that actually matter.
///
/// It opens straight into the exercise. No menu, no options, nothing to read first,
/// because being on your phone is itself one of the most common vaping triggers and this
/// screen is competing with the thing that caused it.
///
/// Both exits are neutral. "I used" is styled as an ordinary secondary action, not as a
/// failure, and it hands the hold time to the slip sheet so the effort is still counted.
struct CravingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let habit: Habit

    /// Reports the seconds held out so Home can open the slip sheet with them attached.
    let onUsed: (Int) -> Void

    @State private var startedAt = Date()
    @State private var phase: Phase = .riding
    @State private var reason: String?
    @State private var trigger: String?
    @State private var heldOutSeconds = 0
    /// Fetched when the screen opens, so Done never waits on the system. The first request
    /// after a reboot can take seconds, and Done must feel instant.
    @State private var askAboutMilestones = false

    private enum Phase { case riding, passed, primer }

    var body: some View {
        Screen(ground: Palette.calm) {
            switch phase {
            case .riding: riding
            case .passed: passed
            case .primer: primer
            }
        }
        .task {
            askAboutMilestones = await MilestoneScheduler.authorizationStatus() == .notDetermined
        }
        .onAppear {
            // One reason for the whole session. Rotating text at someone trying to calm
            // down is noise.
            reason = habit.reasons.randomElement()
        }
    }

    // MARK: - Riding it out

    private var riding: some View {
        VStack(spacing: Space.l) {
            Spacer()

            breathing

            if let reason {
                VStack(alignment: .leading, spacing: Space.xs) {
                    SectionLabel("Your reason")
                    Text(verbatim: "“\(reason)”")
                        .font(Typeface.voice)
                        .foregroundStyle(Palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Space.m)
                .background(Palette.ground, in: RoundedRectangle(cornerRadius: Radius.card))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.card)
                        .strokeBorder(Palette.calmRing, lineWidth: 2)
                )
            }

            Spacer()

            VStack(spacing: Space.s) {
                PrimaryButton("It passed") { finishResisted() }
                SecondaryButton("I used") { finishUsed() }
            }
            .padding(.bottom, Space.l)
        }
    }

    /// A paced breathing exercise rather than an ornament: four seconds in, four seconds
    /// out. The elapsed time sits in the middle so the whole screen is one object.
    @ViewBuilder
    private var breathing: some View {
        if reduceMotion {
            breathingRings(inhaling: true, label: "Breathe slowly", animated: false)
        } else {
            PhaseAnimator([true, false]) { inhaling in
                breathingRings(inhaling: inhaling, label: inhaling ? "Breathe in" : "Breathe out", animated: true)
            } animation: { _ in
                .easeInOut(duration: 4)
            }
        }
    }

    private func breathingRings(inhaling: Bool, label: LocalizedStringKey, animated: Bool) -> some View {
        let scale: CGFloat = animated ? (inhaling ? 1 : 0.84) : 1

        return ZStack {
            Circle()
                .fill(Palette.calmRing)
                .frame(width: 250, height: 250)
                .scaleEffect(scale)
            Circle()
                .fill(Palette.calmRingDeep)
                .frame(width: 190, height: 190)
                .scaleEffect(scale)
            Circle()
                .fill(Palette.ground)
                .frame(width: 132, height: 132)
                .shadow(color: Palette.calmRingDeep, radius: 0, y: 6)

            VStack(spacing: 2) {
                Text(label)
                    .font(Typeface.label)
                    .textCase(.uppercase)
                    .tracking(0.8)
                    .foregroundStyle(Palette.skyInk)
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                    .transaction { $0.animation = nil }
                Text(timerInterval: startedAt...Date.distantFuture, countsDown: false)
                    .font(.system(size: 34, weight: .heavy, design: .rounded).monospacedDigit())
                    .foregroundStyle(Palette.ink)
                    .accessibilityHidden(true)
            }
        }
        .frame(height: 260)
    }

    // MARK: - It passed

    private var passed: some View {
        PinnedActions(ground: Palette.calm) {
            VStack(alignment: .leading, spacing: Space.l) {
            VStack(alignment: .leading, spacing: Space.s) {
                Text("Nice! You waited it out.")
                    .font(Typeface.title)
                    .foregroundStyle(Palette.ink)
                Text(durationText)
                    .font(Typeface.voice)
                    .foregroundStyle(Palette.inkSoft)
            }

            VStack(alignment: .leading, spacing: Space.m) {
                SectionLabel("What set it off?")
                Text("Optional. It helps you spot patterns later.")
                    .font(.footnote)
                    .foregroundStyle(Palette.inkFaint)
                TriggerPicker(selection: $trigger)
            }
            }
            .padding(.vertical, Space.l)
        } actions: {
            PrimaryButton("Done") { save() }
        }
    }

    // MARK: - Notification primer

    /// Asked here rather than during onboarding, and only after something went well.
    /// Asking on first launch trades a permanent refusal for a moment of convenience.
    private var primer: some View {
        PinnedActions(ground: Palette.calm) {
            VStack(alignment: .leading, spacing: Space.m) {
            Text("Want a little note at each milestone?")
                .font(Typeface.title)
                .foregroundStyle(Palette.ink)

            Text("We’ll send a short note at 1 day, 3 days, a week and a month. We’ll never bug you for not opening the app.")
                .font(Typeface.voice)
                .foregroundStyle(Palette.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, Space.l)
        } actions: {
            VStack(spacing: Space.s) {
                PrimaryButton("Yes") {
                    Task {
                        _ = await MilestoneScheduler.requestAuthorization()
                        dismiss()
                    }
                }
                SecondaryButton("Not now") { dismiss() }
            }
        }
    }

    // MARK: - Actions

    private func finishResisted() {
        heldOutSeconds = Int(Date().timeIntervalSince(startedAt))
        withAnimation(.smooth(duration: 0.3)) { phase = .passed }
    }

    private func finishUsed() {
        onUsed(Int(Date().timeIntervalSince(startedAt)))
        dismiss()
    }

    private func save() {
        context.insert(
            CravingEvent(
                occurredAt: startedAt,
                heldOutSeconds: heldOutSeconds,
                resisted: true,
                triggerRaw: trigger
            )
        )

        if askAboutMilestones {
            withAnimation(.smooth(duration: 0.3)) { phase = .primer }
        } else {
            dismiss()
        }
    }

    private var durationText: String {
        let minutes = heldOutSeconds / 60
        let seconds = heldOutSeconds % 60
        return minutes > 0
            ? String(localized: "\(minutes)m \(seconds)s")
            : String(localized: "\(seconds)s")
    }
}
