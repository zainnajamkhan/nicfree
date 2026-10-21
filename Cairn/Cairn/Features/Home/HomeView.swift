//
//  HomeView.swift
//  Cairn
//

import SwiftUI
import SwiftData

/// One question, answered once, with nothing competing for the answer.
///
/// The asymmetry at the bottom is deliberate: riding out a craving is a large primary
/// button, logging a slip is a small quiet link. It should never be easier to record
/// giving in than to sit with it, and that belongs in the hierarchy rather than in a
/// sentence telling someone off.
struct HomeView: View {
    @Query private var habits: [Habit]
    @Query(sort: \DayRecord.day, order: .reverse) private var usedDays: [DayRecord]
    @Query(sort: \CravingEvent.occurredAt) private var cravings: [CravingEvent]

    @State private var loggingSlip = false
    @State private var showingCraving = false
    @State private var pendingSlip = false
    @State private var pendingHoldSeconds = 0

    @ScaledMetric(relativeTo: .largeTitle) private var heroSize: CGFloat = 76

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
        NavigationStack {
            Screen {
                if let habit, let stats {
                    VStack(alignment: .leading, spacing: 0) {
                        hero(stats)
                        observation(stats: stats, habit: habit)

                        Spacer(minLength: Space.xl)

                        rows(stats: stats, habit: habit)
                        actions
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink { HistoryView() } label: {
                        Image(systemName: "square.grid.3x3")
                            .foregroundStyle(Palette.inkSoft)
                    }
                    .accessibilityLabel("History")
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $loggingSlip, onDismiss: { pendingHoldSeconds = 0 }) {
            SlipLogView(existing: todaysRecord, day: today, heldOutSeconds: pendingHoldSeconds)
                .presentationDetents([.medium])
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

    private func hero(_ stats: QuitStats) -> some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            SectionLabel("Vape free")

            Text(stats.lifetimeFreeDays, format: .number)
                .font(Typeface.hero(min(heroSize, 108)))
                .foregroundStyle(Palette.ink)
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Text("days, all time")
                .font(.subheadline)
                .foregroundStyle(Palette.inkSoft)
        }
        .padding(.top, Space.xxl)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(stats.lifetimeFreeDays) days vape free, all time")
        .accessibilityAddTraits(.isHeader)
    }

    @ViewBuilder
    private func observation(stats: QuitStats, habit: Habit) -> some View {
        if let observation = ObservationEngine.daily(stats: stats, habit: habit, cravings: insights) {
            Text(observation.text)
                .font(Typeface.voice)
                .foregroundStyle(Palette.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, Space.l)
        }
    }

    private func rows(stats: QuitStats, habit: Habit) -> some View {
        VStack(spacing: 0) {
            StatRow("Current run", value: dayCount(stats.currentRun))
            StatRow("Longest run", value: dayCount(stats.longestRun))
            StatRow(
                "Not spent",
                value: stats.moneySaved(dailyCost: habit.baselineDailyCost)
                    .formatted(.currency(code: habit.currencyCode).precision(.fractionLength(0)))
            )
        }
    }

    private var actions: some View {
        VStack(spacing: 0) {
            PrimaryButton("I'm having a craving") { showingCraving = true }
                .padding(.top, Space.l)

            Button {
                loggingSlip = true
            } label: {
                Text(todaysRecord == nil ? "Log a slip" : "Edit today's slip")
                    .font(.footnote)
                    .foregroundStyle(Palette.inkFaint)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Space.m)
            }
            .buttonStyle(.plain)
        }
        .padding(.bottom, Space.s)
    }

    private func dayCount(_ value: Int) -> String {
        value == 1
            ? String(localized: "1 day")
            : String(localized: "\(value) days")
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Habit.self, DayRecord.self, CravingEvent.self], inMemory: true)
}
