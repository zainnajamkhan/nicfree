//
//  OnboardingView.swift
//  NicFree
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
    /// Per week for vaping, per day for pouches and cigarettes. Each is how people actually
    /// describe it.
    @State private var amount: Double = 3
    /// What a week of it costs, in the user's own currency. Asked as a weekly total
    /// because nobody knows the price of one pouch, and no default works in every
    /// currency. Empty means no money estimate, which Home simply leaves out.
    @State private var weeklySpend: Double?
    @State private var quitDate: Date = Date()
    @State private var dateChoice: DateChoice = .today
    @State private var reasons: [String] = ["", "", ""]

    private enum DateChoice { case today, yesterday, another }

    private enum Step: Int, CaseIterable {
        case form, amount, date, reasons, ready
    }

    var body: some View {
        Screen {
            // The step scrolls and the button is pinned, so at the largest text sizes the
            // button can never be pushed off the bottom of the screen.
            ScrollView {
                VStack(alignment: .leading, spacing: Space.l) {
                    HStack(spacing: Space.m) {
                        if step != .form {
                            Button(action: back) {
                                Image(systemName: "chevron.left")
                                    .font(.body.weight(.heavy))
                                    .foregroundStyle(Palette.inkSoft)
                                    .frame(width: 44, height: 44)
                                    .background(Palette.surface, in: Circle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Back")
                        }
                        StoneProgress(total: Step.allCases.count, current: step.rawValue)
                    }
                    .frame(minHeight: 44)
                    .padding(.top, Space.l)

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
                }
                .padding(.bottom, Space.l)
                .animation(.smooth(duration: 0.3), value: step)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                PrimaryButton(step == .ready ? "Let’s go!" : "Continue", action: advance)
                    .padding(.vertical, Space.s)
                    .background(Palette.ground)
            }
        }
    }

    // MARK: - Steps

    private var formStep: some View {
        VStack(alignment: .leading, spacing: Space.l) {
            question("What do you use?")

            VStack(alignment: .leading, spacing: Space.s) {
                SectionLabel("Vape")
                choice("Disposables", unit: .disposable)
                choice("Pods or cartridges", unit: .pod)

                SectionLabel("Pouches")
                    .padding(.top, Space.s)
                choice("Nicotine pouches", unit: .pouch)

                SectionLabel("Cigarettes")
                    .padding(.top, Space.s)
                choice("Cigarettes", unit: .cigarette)
            }
        }
    }

    private var amountStep: some View {
        VStack(alignment: .leading, spacing: Space.l) {
            question(amountQuestion)
            aside("Rough numbers are fine.")

            VStack(spacing: Space.m) {
                Stepper(value: $amount, in: 1...(perDay ? 60 : 100), step: 1) {
                    HStack {
                        Text(perDay ? "Per day" : "Per week").foregroundStyle(Palette.inkSoft)
                        Spacer()
                        Text(amount.formatted(.number.precision(.fractionLength(0))))
                            .monospacedDigit()
                    }
                    .font(Typeface.row)
                }

                HStack {
                    Text("Money spent each week").foregroundStyle(Palette.inkSoft)
                    Spacer()
                    TextField("Optional", value: $weeklySpend, format: .currency(code: currencyCode).precision(.fractionLength(0)))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .monospacedDigit()
                        .frame(maxWidth: 160)
                }
                .font(Typeface.row)
            }
        }
    }

    private var dateStep: some View {
        VStack(alignment: .leading, spacing: Space.l) {
            question("When did you stop?")
            aside("Stopped a while ago? Those days count too.")

            VStack(spacing: Space.s) {
                optionRow("Today", isOn: dateChoice == .today) { chooseDate(.today) }
                optionRow("Yesterday", isOn: dateChoice == .yesterday) { chooseDate(.yesterday) }
                optionRow(
                    "Another day",
                    detail: dateChoice == .another ? quitDate.formatted(.dateTime.day().month(.wide).year()) : nil,
                    isOn: dateChoice == .another
                ) { chooseDate(.another) }
            }

            if dateChoice == .another {
                DatePicker("Quit date", selection: $quitDate, in: ...Date(), displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .tint(Palette.accent)
                    .padding(Space.s)
                    .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.card))
            }
        }
    }

    private var reasonsStep: some View {
        VStack(alignment: .leading, spacing: Space.l) {
            question("Why are you stopping?")
            aside("Write them your way. We’ll show them to you when a craving hits.")

            VStack(spacing: Space.s) {
                field(index: 0, placeholder: "So I can climb stairs without stopping")
                field(index: 1, placeholder: "To save money")
                field(index: 2, placeholder: "I don’t want to need it")
            }
        }
    }

    private var readyStep: some View {
        VStack(alignment: .leading, spacing: Space.m) {
            question("That’s it. You’re all set!")
            Text("You don’t need to check in. Every day counts as a free day unless you log a slip. If you’re away for a few days, we’ll ask about them when you’re back.")
                .font(Typeface.voice)
                .foregroundStyle(Palette.inkSoft)
        }
    }

    // MARK: - Pieces

    private func question(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .font(Typeface.title)
            .foregroundStyle(Palette.ink)
    }

    private func aside(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(Palette.inkSoft)
    }

    private func choice(_ title: LocalizedStringKey, unit value: ConsumptionUnit) -> some View {
        optionRow(title, isOn: unit == value) { select(value) }
    }

    /// One tappable option. Selected reads as a green outline and tint, never only a tick.
    private func optionRow(
        _ title: LocalizedStringKey,
        detail: String? = nil,
        isOn: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(Typeface.row).foregroundStyle(Palette.ink)
                    if let detail {
                        Text(detail).font(.caption.weight(.semibold)).foregroundStyle(Palette.accent)
                    }
                }
                Spacer()
                if isOn {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Palette.accent)
                }
            }
            .padding(Space.m)
            .frame(minHeight: 56)
            .background(
                RoundedRectangle(cornerRadius: Radius.button)
                    .fill(isOn ? Palette.accentQuiet : Palette.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.button)
                    .strokeBorder(isOn ? Palette.leaf : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? [.isSelected] : [])
    }

    private func field(index: Int, placeholder: LocalizedStringKey) -> some View {
        TextField(placeholder, text: $reasons[index], axis: .vertical)
            .font(Typeface.voiceSmall)
            .padding(Space.m)
            .background(RoundedRectangle(cornerRadius: Radius.button).fill(Palette.surface))
    }

    private var unitsPerWeek: Double { perDay ? amount * 7 : amount }

    /// Pouches and cigarettes are counted per day; vaping per week.
    private var perDay: Bool { unit == .pouch || unit == .cigarette }

    /// Names the exact thing picked on the first step, so the question reads as a follow-on.
    private var amountQuestion: LocalizedStringKey {
        switch unit {
        case .disposable: "Roughly how many disposables do you use in a week?"
        case .pod: "Roughly how many pods do you use in a week?"
        case .pouch: "Roughly how many pouches do you use in a day?"
        case .cigarette: "Roughly how many cigarettes do you smoke in a day?"
        case .millilitre, .session: "Roughly how much do you use in a week?"
        }
    }

    /// Each choice gets its own sensible starting amount, rather than carrying over a number
    /// from a different product.
    private func select(_ value: ConsumptionUnit) {
        guard value != unit else { return }
        unit = value
        amount = switch value {
        case .pouch: 8
        case .cigarette: 10
        default: 3
        }
    }

    private func form(for unit: ConsumptionUnit) -> NicotineForm {
        switch unit {
        case .pouch: .pouch
        case .cigarette: .cigarette
        default: .vape
        }
    }

    private var currencyCode: String {
        Locale.current.currency?.identifier ?? "USD"
    }

    // MARK: - Flow

    private func back() {
        guard let previous = Step(rawValue: step.rawValue - 1) else { return }
        step = previous
    }

    private func chooseDate(_ choice: DateChoice) {
        dateChoice = choice
        let today = Calendar.current.startOfDay(for: Date())
        switch choice {
        case .today: quitDate = Date()
        case .yesterday: quitDate = Calendar.current.date(byAdding: .day, value: -1, to: today) ?? today
        case .another:
            // Start the calendar a week back, a likelier answer than today for "another day".
            if Calendar.current.isDateInToday(quitDate) {
                quitDate = Calendar.current.date(byAdding: .day, value: -7, to: today) ?? today
            }
        }
    }

    private func advance() {
        guard let next = Step(rawValue: step.rawValue + 1) else {
            finish()
            return
        }
        step = next
    }

    private func finish() {
        let habit = Habit(
            form: form(for: unit),
            unit: unit,
            baselineUnitsPerWeek: unitsPerWeek,
            costPerUnit: (weeklySpend ?? 0) / unitsPerWeek,
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
