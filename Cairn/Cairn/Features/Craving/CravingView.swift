//
//  CravingView.swift
//  Cairn
//

import SwiftUI
import SwiftData

/// The four minutes that actually matter.
///
/// It opens straight into the exercise. No menu, no options, nothing to read first,
/// because being on your phone is itself one of the most common vaping triggers and this
/// screen is competing with the thing that caused it.
///
/// Both exits are neutral. "I vaped" is styled as an ordinary secondary action, not as a
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
    @State private var trigger: CravingTrigger?
    @State private var heldOutSeconds = 0

    private enum Phase { case riding, passed, primer }

    var body: some View {
        Screen {
            switch phase {
            case .riding: riding
            case .passed: passed
            case .primer: primer
            }
        }
        .onAppear {
            // One reason for the whole session. Rotating text at someone trying to calm
            // down is noise.
            reason = habit.reasons.randomElement()
        }
    }

    // MARK: - Riding it out

    private var riding: some View {
        VStack(spacing: Space.xl) {
            Spacer()

            breathing

            Text(timerInterval: startedAt...Date.distantFuture, countsDown: false)
                .font(.system(size: 34, weight: .medium).monospacedDigit())
                .foregroundStyle(Palette.ink)
                .accessibilityHidden(true)

            if let reason {
                Text(verbatim: "“\(reason)”")
                    .font(Typeface.voice)
                    .foregroundStyle(Palette.ink)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            VStack(spacing: Space.s) {
                PrimaryButton("It passed") { finishResisted() }
                SecondaryButton("I vaped") { finishUsed() }
            }
            .padding(.bottom, Space.l)
        }
    }

    /// The only animation in the app, and it is a paced breathing exercise rather than an
    /// ornament: four seconds in, four seconds out.
    @ViewBuilder
    private var breathing: some View {
        if reduceMotion {
            VStack(spacing: Space.m) {
                Circle()
                    .fill(Palette.accentQuiet)
                    .opacity(0.5)
                    .frame(width: 150, height: 150)
                SectionLabel("Breathe slowly")
            }
        } else {
            PhaseAnimator([true, false]) { inhaling in
                VStack(spacing: Space.m) {
                    Circle()
                        .fill(Palette.accentQuiet)
                        .opacity(0.5)
                        .frame(width: 160, height: 160)
                        .scaleEffect(inhaling ? 1 : 0.82)
                    SectionLabel(inhaling ? "Breathe in" : "Breathe out")
                }
            } animation: { _ in
                .easeInOut(duration: 4)
            }
        }
    }

    // MARK: - It passed

    private var passed: some View {
        VStack(alignment: .leading, spacing: Space.l) {
            Spacer()

            VStack(alignment: .leading, spacing: Space.s) {
                Text("You waited it out.")
                    .font(.system(.title, design: .serif))
                    .foregroundStyle(Palette.ink)
                Text(durationText)
                    .font(Typeface.voice)
                    .foregroundStyle(Palette.inkSoft)
            }

            VStack(alignment: .leading, spacing: Space.m) {
                SectionLabel("What set it off?")
                Text("Optional. It is what makes the patterns worth reading later.")
                    .font(.footnote)
                    .foregroundStyle(Palette.inkFaint)
                FlowLayout {
                    ForEach(CravingTrigger.allCases, id: \.self) { value in
                        Chip(String(localized: value.title), isOn: trigger == value) {
                            trigger = value
                        }
                    }
                }
            }

            Spacer()

            PrimaryButton("Done") { save() }
                .padding(.bottom, Space.l)
        }
    }

    // MARK: - Notification primer

    /// Asked here rather than during onboarding, and only after something went well.
    /// Asking on first launch trades a permanent refusal for a moment of convenience.
    private var primer: some View {
        VStack(alignment: .leading, spacing: Space.m) {
            Spacer()

            Text("Should we mark the milestones?")
                .font(.system(.title, design: .serif))
                .foregroundStyle(Palette.ink)

            Text("A short note at a day, three days, a week, a month. Nothing else, ever. Cairn will never nudge you for not opening it, because there is nothing to keep up with.")
                .font(Typeface.voice)
                .foregroundStyle(Palette.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            VStack(spacing: Space.s) {
                PrimaryButton("Yes") {
                    Task {
                        _ = await MilestoneScheduler.requestAuthorization()
                        dismiss()
                    }
                }
                SecondaryButton("Not now") { dismiss() }
            }
            .padding(.bottom, Space.l)
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
                trigger: trigger
            )
        )

        Task {
            if await MilestoneScheduler.authorizationStatus() == .notDetermined {
                withAnimation(.smooth(duration: 0.3)) { phase = .primer }
            } else {
                dismiss()
            }
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
