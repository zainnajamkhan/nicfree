//
//  HomeView.swift
//  Cairn
//

import SwiftUI
import SwiftData

/// Three numbers that only grow, a sprout that grows with them, and one big button.
///
/// The asymmetry at the bottom is deliberate: riding out a craving is a large primary
/// button, logging a slip is a small quiet link. It should never be easier to record
/// giving in than to sit with it, and that belongs in the hierarchy rather than in a
/// sentence telling someone off.
struct HomeView: View {
    @Environment(\.storeIsTemporary) private var storeIsTemporary
    @Query private var habits: [Habit]
    @Query(sort: \DayRecord.day, order: .reverse) private var usedDays: [DayRecord]
    @Query(sort: \CravingEvent.occurredAt) private var cravings: [CravingEvent]

    @State private var loggingSlip = false
    @State private var showingCraving = false
    @State private var pendingSlip = false
    @State private var pendingHoldSeconds = 0
    @State private var showingSettings = false

    private var habit: Habit? { habits.first }

    private var stats: QuitStats? {
        guard let habit else { return nil }
        return QuitStats(
            quitStartedAt: habit.quitStartedAt,
            usedDays: Set(usedDays.map(\.day))
        )
    }

    private var insights: CravingInsights {
        CravingInsights(
            events: cravings.map {
                CravingInsights.Event(
                    occurredAt: $0.occurredAt,
                    heldOutSeconds: $0.heldOutSeconds,
                    resisted: $0.resisted,
                    trigger: $0.triggerRaw
                )
            }
        )
    }

    private var today: Date { Calendar.current.startOfDay(for: Date()) }
    private var todaysRecord: DayRecord? { usedDays.first { $0.day == today } }

    var body: some View {
        Screen {
            if let habit, let stats {
                ScrollView {
                    VStack(spacing: Space.m) {
                        if storeIsTemporary { temporaryStoreNotice }
                        chips(stats: stats, habit: habit)
                        sproutCard(stats: stats, habit: habit)
                        WeekRow(stats: stats, usedDays: Set(usedDays.map(\.day)))
                    }
                    .padding(.top, Space.m)
                }
                .scrollBounceBehavior(.basedOnSize)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    actions
                        .background(Palette.ground)
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            if let habit { SettingsView(habit: habit) }
        }
        .sheet(isPresented: $loggingSlip, onDismiss: { pendingHoldSeconds = 0 }) {
            SlipLogView(existing: todaysRecord, day: today, heldOutSeconds: pendingHoldSeconds)
                .presentationDetents([.medium, .large])
        }
        .fullScreenCover(isPresented: $showingCraving, onDismiss: {
            if pendingSlip {
                pendingSlip = false
                loggingSlip = true
            }
        }) {
            if let habit {
                CravingView(habit: habit) { seconds in
                    pendingHoldSeconds = seconds
                    pendingSlip = true
                }
            }
        }
        // Milestones count free days, so a slip moves the next one. Rebuilding the whole
        // schedule whenever that number changes is the only way to keep them honest.
        .task(id: stats?.lifetimeFreeDays ?? -1) {
            guard let stats else { return }
            await MilestoneScheduler.reschedule(freeDays: stats.lifetimeFreeDays)
        }
    }

    // MARK: - Pieces

    private func chips(stats: QuitStats, habit: Habit) -> some View {
        let money = stats.moneySaved(dailyCost: habit.baselineDailyCost)
            .formatted(.currency(code: habit.currencyCode).precision(.fractionLength(0)))

        return HStack(spacing: Space.s) {
            StatChip(
                symbol: "leaf.fill",
                value: stats.lifetimeFreeDays.formatted(),
                fill: Palette.accentQuiet,
                tint: Palette.accent,
                ink: Palette.ink,
                label: "Free days, all time"
            )
            StatChip(
                symbol: "shield.fill",
                value: insights.resistedCount.formatted(),
                fill: Palette.skyQuiet,
                tint: Palette.sky,
                ink: Palette.skyInk,
                label: "Cravings beaten"
            )
            // No spend given in onboarding means no estimate, rather than a zero that
            // reads like nothing was saved.
            if habit.baselineDailyCost > 0 {
                StatChip(
                    symbol: "dollarsign.circle.fill",
                    value: money,
                    fill: Palette.sunQuiet,
                    tint: Palette.sun,
                    ink: Palette.sunInk,
                    label: "Not spent"
                )
            }

            Button {
                showingSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.callout.weight(.bold))
                    .foregroundStyle(Palette.inkSoft)
                    .frame(width: 44, height: 44)
                    .background(Palette.surface, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
        }
    }

    private func sproutCard(stats: QuitStats, habit: Habit) -> some View {
        let free = stats.lifetimeFreeDays
        let line = ObservationEngine.daily(stats: stats, habit: habit, cravings: insights)?.text
            ?? String(inflecting: "^[\(free) free day](inflect: true), and that number only goes up.")

        return VStack(spacing: Space.m) {
            Text(line)
                .font(Typeface.voiceSmall)
                .foregroundStyle(Palette.ink)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Space.m - 2)
                .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.button))

            Sprout(freeDays: free)
                .frame(height: 180)

            if let next = MilestoneScheduler.milestones.first(where: { $0 > free }) {
                nextMilestone(free: free, next: next)
            }
        }
        .padding(Space.m + 4)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card)
                .stroke(Palette.hairline, lineWidth: 2)
        )
    }

    private func nextMilestone(free: Int, next: Int) -> some View {
        VStack(spacing: Space.s - 2) {
            HStack {
                Text(String(inflecting: "Next: ^[\(next) day](inflect: true)"))
                Spacer()
                Text("\(next - free) to go")
                    .foregroundStyle(Palette.inkSoft)
            }
            .font(Typeface.row)
            .foregroundStyle(Palette.ink)

            ProgressView(value: Double(free), total: Double(next))
                .progressViewStyle(LeafProgressStyle())
        }
        .accessibilityElement(children: .combine)
    }

    /// Plain about what is happening and what it means, without alarm. Never red.
    private var temporaryStoreNotice: some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            Text("Your saved history could not be opened")
                .font(.system(.body, design: .rounded, weight: .heavy))
                .foregroundStyle(Palette.sunInk)
            Text("Nothing logged right now will be kept. Close NicFree fully and open it again. NicFree has not deleted anything.")
                .font(Typeface.row)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Space.m)
        .background(Palette.sunQuiet, in: RoundedRectangle(cornerRadius: Radius.button))
        .accessibilityElement(children: .combine)
    }

    private var actions: some View {
        VStack(spacing: 0) {
            PrimaryButton("I'm having a craving") { showingCraving = true }
                .padding(.horizontal, Space.l)
                .padding(.top, Space.s)

            Button {
                loggingSlip = true
            } label: {
                Text(todaysRecord == nil ? "Log a slip" : "Edit today's slip")
                    .font(Typeface.row)
                    .foregroundStyle(Palette.inkFaint)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Week row

/// The last seven days. A free day is a filled circle, a used day is a rounded square in
/// clay, so the two differ in shape as well as tone. Today shows as an open ring because
/// the day is not over.
private struct WeekRow: View {
    let stats: QuitStats
    let usedDays: Set<Date>

    private enum Mark { case free, used, today, before }

    private struct Entry: Identifiable {
        let id: Date
        let label: String
        let spoken: String
        let mark: Mark
    }

    private var entries: [Entry] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let start = calendar.startOfDay(for: stats.quitStartedAt)

        return (0..<7).reversed().compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let mark: Mark
            if usedDays.contains(day) {
                mark = .used
            } else if day == today {
                mark = .today
            } else if day < start {
                mark = .before
            } else {
                mark = .free
            }
            return Entry(
                id: day,
                label: day.formatted(.dateTime.weekday(.narrow)),
                spoken: day.formatted(.dateTime.weekday(.wide)),
                mark: mark
            )
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(entries) { entry in
                VStack(spacing: Space.xs) {
                    Text(entry.label)
                        .font(Typeface.label)
                        .foregroundStyle(Palette.inkSoft)
                    mark(entry.mark)
                        .frame(width: 34, height: 34)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(entry.spoken), \(spokenState(entry.mark))")
            }
        }
    }

    @ViewBuilder
    private func mark(_ mark: Mark) -> some View {
        switch mark {
        case .free:
            Circle().fill(Palette.leaf)
        case .used:
            RoundedRectangle(cornerRadius: 10)
                .fill(Palette.clayQuiet)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Palette.clay, lineWidth: 2))
        case .today:
            Circle().stroke(Palette.leaf, lineWidth: 3)
        case .before:
            Circle().fill(Palette.hairline).scaleEffect(0.5)
        }
    }

    private func spokenState(_ mark: Mark) -> String {
        switch mark {
        case .free: String(localized: "free")
        case .used: String(localized: "used")
        case .today: String(localized: "today so far")
        case .before: String(localized: "before you started")
        }
    }
}

// MARK: - Progress style

struct LeafProgressStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Palette.sunk)
                Capsule()
                    .fill(Palette.leaf)
                    .frame(width: proxy.size.width * (configuration.fractionCompleted ?? 0))
            }
        }
        .frame(height: 14)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Habit.self, DayRecord.self, CravingEvent.self], inMemory: true)
}
