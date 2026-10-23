//
//  SlipLogView.swift
//  NicFree
//

import SwiftUI
import SwiftData
import UIKit

/// Two taps, no counting. Opened on an existing slip, it edits it or removes it.
///
/// Asking a vaper how many puffs they took produces either a blank field or an invented
/// number, so intensity is coarse and deliberately unarithmetic. None of it touches the
/// hero number, which is binary on whether nicotine was used at all.
struct SlipLogView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var cravings: [CravingEvent]

    let existing: DayRecord?
    let day: Date

    /// Seconds held out before using, when this arrived from the craving screen. The
    /// effort still counts, even though the craving ended in use.
    var heldOutSeconds: Int = 0

    @State private var intensity: UsageIntensity?
    @State private var trigger: String?
    @State private var outcome: Outcome?
    @State private var confirmingRemove = false

    private enum Outcome { case saved, removed }

    var body: some View {
        Screen {
            if let outcome {
                confirmation(outcome)
            } else {
                form
            }
        }
        .onAppear {
            intensity = existing?.intensity
            trigger = linkedCraving?.triggerRaw
        }
        .alert("Remove this slip?", isPresented: $confirmingRemove) {
            Button("Remove it", action: remove)
            Button("Keep it", role: .cancel) {}
        } message: {
            Text("This day will count as a free day again.")
        }
    }

    /// The craving a slip wrote when it was logged: the one that ended in use on the same
    /// day. A day has at most one slip, so there's at most one of these.
    private var linkedCraving: CravingEvent? {
        guard existing != nil else { return nil }
        let calendar = Calendar.current
        return cravings.first { !$0.resisted && calendar.isDate($0.occurredAt, inSameDayAs: day) }
    }

    // MARK: - Form

    private var form: some View {
        ScrollView {
            fields
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 0) {
                PrimaryButton("Save", action: save)
                    .disabled(intensity == nil)
                    .opacity(intensity == nil ? 0.4 : 1)
                // Quiet on purpose, like "Log a slip" on Home. Logged by mistake is common.
                if existing != nil {
                    Button("Remove this slip") { confirmingRemove = true }
                        .font(Typeface.row)
                        .foregroundStyle(Palette.inkFaint)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .buttonStyle(.plain)
                }
            }
            .padding(.vertical, Space.s)
            .background(Palette.ground)
        }
    }

    /// The Save button lives outside the scroll view so it can never be pushed below the
    /// bottom of a half-height sheet by larger text or more chips.
    private var fields: some View {
        VStack(alignment: .leading, spacing: Space.l) {
            VStack(alignment: .leading, spacing: Space.m) {
                SectionLabel("How much?")
                FlowLayout {
                    ForEach(UsageIntensity.allCases, id: \.self) { value in
                        Chip(String(localized: value.title), isOn: intensity == value) {
                            intensity = value
                        }
                    }
                }
            }
            .padding(.top, Space.xl)

            VStack(alignment: .leading, spacing: Space.m) {
                SectionLabel("What set it off?")
                TriggerPicker(selection: $trigger)
            }
        }
        .padding(.bottom, Space.m)
    }

    // MARK: - Confirmation

    /// The most important sentence in the app, so it stays until they have read it. It used
    /// to vanish after 1.8 seconds, which is too fast on a bad day.
    private func confirmation(_ outcome: Outcome) -> some View {
        PinnedActions {
            VStack(spacing: Space.s) {
                Text(outcome == .saved ? "Got it." : "Removed.")
                    .font(Typeface.voice)
                    .foregroundStyle(Palette.inkSoft)
                Text(outcome == .saved
                     ? "Every free day you’ve already had is still there."
                     : "That day counts as a free day again.")
                    .font(Typeface.title)
                    .foregroundStyle(Palette.accent)
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
        } actions: {
            PrimaryButton("Done") { dismiss() }
        }
    }

    // MARK: - Save

    private func save() {
        if let existing {
            existing.intensity = intensity
            if let linkedCraving {
                linkedCraving.triggerRaw = trigger
            } else if trigger != nil {
                // Catch-up slips and older ones have no craving yet; one gives the trigger a home.
                context.insert(CravingEvent(occurredAt: momentOnDay, resisted: false, triggerRaw: trigger))
            }
        } else {
            context.insert(DayRecord(day: day, intensity: intensity))

            // A slip is a craving that ended in use, so the trigger belongs in the same
            // place resisted cravings go. That is what lets insights rank triggers across
            // both outcomes rather than only the ones that were survived.
            if trigger != nil || heldOutSeconds > 0 {
                context.insert(
                    CravingEvent(heldOutSeconds: heldOutSeconds, resisted: false, triggerRaw: trigger)
                )
            }
        }

        // A soft tap. The success haptic is never used here: a system sound that means
        // "well done" firing at this moment would be grotesque.
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()

        withAnimation(.smooth(duration: 0.3)) { outcome = .saved }
    }

    /// Logged by mistake: the day goes back to free, and its craving goes with it.
    private func remove() {
        if let linkedCraving { context.delete(linkedCraving) }
        if let existing { context.delete(existing) }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.smooth(duration: 0.3)) { outcome = .removed }
    }

    /// Now for today; midday for an earlier day, so it never lands on the wrong date.
    private var momentOnDay: Date {
        let calendar = Calendar.current
        if calendar.isDateInToday(day) { return Date() }
        return calendar.date(byAdding: .hour, value: 12, to: calendar.startOfDay(for: day)) ?? day
    }
}

#Preview {
    SlipLogView(existing: nil, day: Calendar.current.startOfDay(for: Date()))
        .modelContainer(for: [Habit.self, DayRecord.self, CravingEvent.self], inMemory: true)
}
