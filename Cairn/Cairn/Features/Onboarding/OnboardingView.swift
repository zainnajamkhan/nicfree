//
//  OnboardingView.swift
//  Cairn
//

import SwiftUI
import SwiftData

/// Five steps, defaults on everything, under a minute.
///
/// No account, no paywall and no permission prompts. Asking for notifications here would
/// trade a permanent refusal for a moment of convenience, so it happens later, at the
/// first milestone.
struct OnboardingView: View {
    @Environment(\.modelContext) private var context

    @State private var step: Step = .form
    @State private var unit: ConsumptionUnit = .disposable
    @State private var unitsPerWeek: Double = 3
    @State private var costPerUnit: Double = 25
    @State private var quitDate: Date = Date()
    @State private var reasons: [String] = ["", "", ""]

    private enum Step: Int, CaseIterable {
        case form, amount, date, reasons, ready
    }

    var body: some View {
        Screen {
            VStack(alignment: .leading, spacing: Space.l) {
                StoneProgress(total: Step.allCases.count, current: step.rawValue)
                    .padding(.top, Space.xl)

                Group {
                    switch step {
                    case .form: formStep
                    case .amount: amountStep
                    case .date: dateStep
                    case .reasons: reasonsStep
                    case .ready: readyStep
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: Space.l)

                PrimaryButton(step == .ready ? "Start" : "Continue", action: advance)
                    .padding(.bottom, Space.l)
            }
            .animation(.smooth(duration: 0.3), value: step)
        }
    }

    // MARK: - Steps

    private var formStep: some View {
        VStack(alignment: .leading, spacing: Space.l) {
            question("What do you vape?")

            VStack(spacing: Space.s) {
                choice("Disposables", unit: .disposable)
                choice("Pods or cartridges", unit: .pod)
                choice("Refillable, by the millilitre", unit: .millilitre)
            }
        }
    }

    private var amountStep: some View {
        VStack(alignment: .leading, spacing: Space.l) {
            question("Roughly how much, in a week?")
            aside("A rough number is fine. It only shapes the money estimate, never the day count.")

            VStack(spacing: Space.m) {
                Stepper(value: $unitsPerWeek, in: 1...100, step: 1) {
                    HStack {
                        Text("Per week").foregroundStyle(Palette.inkSoft)
                        Spacer()
                        Text(unitsPerWeek.formatted(.number.precision(.fractionLength(0))))
                            .monospacedDigit()
                    }
                    .font(Typeface.row)
                }

                Stepper(value: $costPerUnit, in: 1...500, step: 1) {
                    HStack {
                        Text("Cost of one").foregroundStyle(Palette.inkSoft)
                        Spacer()
                        Text(costPerUnit.formatted(.currency(code: currencyCode).precision(.fractionLength(0))))
                            .monospacedDigit()
                    }
                    .font(Typeface.row)
                }
            }
        }
    }

    private var dateStep: some View {
        VStack(alignment: .leading, spacing: Space.l) {
            question("When did you stop?")
            aside("Today is fine. If you stopped a while ago, all of those days count.")

            DatePicker(
                "Quit date",
                selection: $quitDate,
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .labelsHidden()
        }
    }

    private var reasonsStep: some View {
        VStack(alignment: .leading, spacing: Space.l) {
            question("Why are you stopping?")
            aside("In your own words. These come back to you during a craving, which is the only time they matter.")

            VStack(spacing: Space.s) {
                field(index: 0, placeholder: "So I can climb stairs without stopping")
                field(index: 1, placeholder: "The money")
                field(index: 2, placeholder: "I do not want to need it")
            }
        }
    }

    private var readyStep: some View {
        VStack(alignment: .leading, spacing: Space.m) {
            question("That is everything.")
            Text("There is nothing to check in to. A day you do not open Cairn counts as a day free, so come back only when you need to.")
                .font(Typeface.voice)
                .foregroundStyle(Palette.inkSoft)
        }
    }

    // MARK: - Pieces

    private func question(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .font(.system(.title, design: .serif))
            .foregroundStyle(Palette.ink)
    }

    private func aside(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(Palette.inkSoft)
    }

    private func choice(_ title: LocalizedStringKey, unit value: ConsumptionUnit) -> some View {
        Button {
            unit = value
        } label: {
            HStack {
                Text(title).font(Typeface.row).foregroundStyle(Palette.ink)
                Spacer()
                if unit == value {
                    Image(systemName: "checkmark").foregroundStyle(Palette.accent)
                }
            }
            .padding(Space.m)
            .background(
                RoundedRectangle(cornerRadius: Radius.button)
                    .fill(unit == value ? Palette.accentQuiet.opacity(0.35) : Palette.surface)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(unit == value ? [.isSelected] : [])
    }

    private func field(index: Int, placeholder: LocalizedStringKey) -> some View {
        TextField(placeholder, text: $reasons[index], axis: .vertical)
            .font(Typeface.voiceSmall)
            .padding(Space.m)
            .background(RoundedRectangle(cornerRadius: Radius.button).fill(Palette.surface))
    }

    private var currencyCode: String {
        Locale.current.currency?.identifier ?? "USD"
    }

    // MARK: - Flow

    private func advance() {
        guard let next = Step(rawValue: step.rawValue + 1) else {
            finish()
            return
        }
        step = next
    }

    private func finish() {
        let habit = Habit(
            form: .vape,
            unit: unit,
            baselineUnitsPerWeek: unitsPerWeek,
            costPerUnit: costPerUnit,
            nicotineMgPerUnit: unit.defaultNicotineMg,
            currencyCode: currencyCode,
            quitStartedAt: quitDate,
            reasons: reasons.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        )
        context.insert(habit)
    }
}

extension ConsumptionUnit {
    /// Sensible defaults so onboarding never asks about milligrams. Editable in Settings
    /// for anyone who cares about the exact figure.
    var defaultNicotineMg: Double {
        switch self {
        case .disposable, .pod: 40
        case .millilitre: 20
        case .cigarette: 12
        case .pouch: 8
        case .session: 60
        }
    }
}

#Preview {
    OnboardingView()
        .modelContainer(for: [Habit.self, DayRecord.self, CravingEvent.self], inMemory: true)
}
