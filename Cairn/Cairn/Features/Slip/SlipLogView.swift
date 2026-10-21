//
//  SlipLogView.swift
//  Cairn
//

import SwiftUI
import SwiftData
import UIKit

/// Two taps, no counting.
///
/// Asking a vaper how many puffs they took produces either a blank field or an invented
/// number, so intensity is coarse and deliberately unarithmetic. None of it touches the
/// hero number, which is binary on whether nicotine was used at all.
struct SlipLogView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let existing: DayRecord?
    let day: Date

    /// Seconds held out before using, when this arrived from the craving screen. The
    /// effort still counts, even though the craving ended in use.
    var heldOutSeconds: Int = 0

    @State private var intensity: UsageIntensity?
    @State private var trigger: CravingTrigger?
    @State private var saved = false

    var body: some View {
        Screen {
            if saved {
                confirmation
            } else {
                form
            }
        }
        .onAppear {
            intensity = existing?.intensity
        }
    }

    // MARK: - Form

    private var form: some View {
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
                FlowLayout {
                    ForEach(CravingTrigger.allCases, id: \.self) { value in
                        Chip(String(localized: value.title), isOn: trigger == value) {
                            trigger = value
                        }
                    }
                }
            }

            Spacer(minLength: Space.m)

            PrimaryButton("Save", action: save)
                .disabled(intensity == nil)
                .opacity(intensity == nil ? 0.4 : 1)
                .padding(.bottom, Space.l)
        }
    }

    // MARK: - Confirmation

    /// The most important five words in the app.
    private var confirmation: some View {
        VStack(spacing: Space.s) {
            Text("Logged.")
                .font(Typeface.voice)
                .foregroundStyle(Palette.inkSoft)
            Text("Your total is unchanged.")
                .font(Typeface.title)
                .foregroundStyle(Palette.accent)
        }
        .multilineTextAlignment(.center)
        .task {
            try? await Task.sleep(for: .seconds(1.8))
            dismiss()
        }
    }

    // MARK: - Save

    private func save() {
        if let existing {
            existing.intensity = intensity
        } else {
            context.insert(DayRecord(day: day, intensity: intensity))

            // A slip is a craving that ended in use, so the trigger belongs in the same
            // place resisted cravings go. That is what lets insights rank triggers across
            // both outcomes rather than only the ones that were survived.
            if trigger != nil || heldOutSeconds > 0 {
                context.insert(
                    CravingEvent(heldOutSeconds: heldOutSeconds, resisted: false, trigger: trigger)
                )
            }
        }

        // A soft tap. The success haptic is never used here: a system sound that means
        // "well done" firing at this moment would be grotesque.
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()

        withAnimation(.smooth(duration: 0.3)) { saved = true }
    }
}

#Preview {
    SlipLogView(existing: nil, day: Calendar.current.startOfDay(for: Date()))
        .modelContainer(for: [Habit.self, DayRecord.self, CravingEvent.self], inMemory: true)
}
