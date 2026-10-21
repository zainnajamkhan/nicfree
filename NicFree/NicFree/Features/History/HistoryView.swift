//
//  HistoryView.swift
//  NicFree
//

import SwiftUI
import SwiftData
import Charts

/// The record, in three readings: every day at a glance, the total over time, and the
/// individual events.
///
/// Free: the last seven days of events. Paid: the year grid, the total over time, and
/// every event.
struct HistoryView: View {
    @Environment(PurchaseStore.self) private var store
    @State private var showingPaywall = false

    @Query private var habits: [Habit]
    @Query(sort: \DayRecord.day, order: .reverse) private var usedDays: [DayRecord]
    @Query(sort: \CravingEvent.occurredAt, order: .reverse) private var cravings: [CravingEvent]

    private var habit: Habit? { habits.first }

    private var stats: QuitStats? {
        guard let habit else { return nil }
        return QuitStats(
            quitStartedAt: habit.quitStartedAt,
            usedDays: Set(usedDays.map(\.day))
        )
    }

    var body: some View {
        ZStack {
            Palette.ground.ignoresSafeArea()

            if let stats {
                ScrollView {
                    VStack(alignment: .leading, spacing: Space.xl) {
                        if store.isUnlocked {
                            gridSection(stats)
                            chartSection(stats)
                        } else {
                            LockedCard(
                                title: "Your full history",
                                detail: "Every day since you stopped on one grid, and your total drawn over time. The last seven days are below."
                            ) { showingPaywall = true }
                            .padding(.top, Space.m)
                        }
                        timelineSection
                    }
                    .padding(.horizontal, Space.l)
                    .padding(.bottom, Space.xxl)
                }
            }
        }
        .sheet(isPresented: $showingPaywall) { PaywallView() }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .tint(Palette.accent)
    }

    // MARK: - Grid

    private func gridSection(_ stats: QuitStats) -> some View {
        VStack(alignment: .leading, spacing: Space.m) {
            SectionLabel("Every day since you stopped")

            YearGrid(points: stats.series())

            YearGridLegend()

            VStack(spacing: 0) {
                StatRow(
                    "Days free",
                    value: String(localized: "\(stats.lifetimeFreeDays) of \(stats.totalDaysTracked)")
                )
                StatRow("Longest run", value: String(inflecting: "^[\(stats.longestRun) day](inflect: true)"))
            }
        }
        .padding(.top, Space.m)
    }

    // MARK: - Chart

    /// A single series, so the label names it and there is no legend. The line cannot
    /// fall: on a used day it simply holds flat, which is the thesis drawn rather than
    /// argued.
    private func chartSection(_ stats: QuitStats) -> some View {
        let points = stats.series()

        return VStack(alignment: .leading, spacing: Space.m) {
            SectionLabel("Your total, over time")

            Chart {
                ForEach(points) { point in
                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Days free", point.cumulativeFreeDays)
                    )
                    .foregroundStyle(
                        .linearGradient(
                            colors: [Palette.accent.opacity(0.25), Palette.accent.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Days free", point.cumulativeFreeDays)
                    )
                    .foregroundStyle(Palette.accent)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }

                if let last = points.last {
                    PointMark(
                        x: .value("Date", last.date),
                        y: .value("Days free", last.cumulativeFreeDays)
                    )
                    .foregroundStyle(Palette.accent)
                    .symbolSize(60)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) {
                    AxisGridLine().foregroundStyle(Palette.hairline)
                    AxisValueLabel().foregroundStyle(Palette.inkFaint)
                }
            }
            .chartXAxis {
                AxisMarks {
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                        .foregroundStyle(Palette.inkFaint)
                }
            }
            .frame(height: 170)
            .accessibilityLabel("Total days free over time")
            .accessibilityValue(String(inflecting: "^[\(stats.lifetimeFreeDays) day](inflect: true)"))
        }
    }

    // MARK: - Timeline

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: Space.m) {
            SectionLabel("Events")

            if entries.isEmpty {
                Text("Nothing logged yet. That is the ideal outcome, not a gap.")
                    .font(Typeface.voiceSmall)
                    .foregroundStyle(Palette.inkFaint)
            } else {
                VStack(spacing: 0) {
                    ForEach(entries) { entry in
                        row(entry)
                    }
                }
            }
        }
    }

    private func row(_ entry: TimelineEntry) -> some View {
        VStack(spacing: 0) {
            Divider().overlay(Palette.hairline)
            HStack(alignment: .firstTextBaseline, spacing: Space.m) {
                Circle()
                    .fill(entry.isSlip ? Palette.clayQuiet : Palette.accentQuiet)
                    .frame(width: 8, height: 8)

                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.title).foregroundStyle(Palette.ink)
                    if let detail = entry.detail {
                        Text(detail).font(.caption).foregroundStyle(Palette.inkFaint)
                    }
                }

                Spacer()

                Text(entry.date.formatted(.dateTime.day().month(.abbreviated)))
                    .font(.caption)
                    .foregroundStyle(Palette.inkFaint)
                    .monospacedDigit()
            }
            .font(Typeface.row)
            .padding(.vertical, Space.m * 0.7)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Entries

    /// Slips come from `DayRecord`, and only *resisted* cravings are listed. A craving
    /// that ended in use already wrote a day record, so listing both would show the same
    /// moment twice.
    private var entries: [TimelineEntry] {
        let slips = usedDays.map { record in
            TimelineEntry(
                id: "slip-\(record.day.timeIntervalSince1970)",
                date: record.day,
                isSlip: true,
                title: String(localized: "Used"),
                detail: record.intensity.map { String(localized: $0.title) }
            )
        }

        let held = cravings.filter(\.resisted).map { craving in
            TimelineEntry(
                id: "craving-\(craving.occurredAt.timeIntervalSince1970)",
                date: craving.occurredAt,
                isSlip: false,
                title: String(localized: "Rode out a craving"),
                detail: craving.heldOutSeconds > 0
                    ? Duration.seconds(craving.heldOutSeconds)
                        .formatted(.units(allowed: [.minutes, .seconds], width: .narrow))
                    : nil
            )
        }

        let all = (slips + held).sorted { $0.date > $1.date }
        guard !store.isUnlocked else { return Array(all.prefix(40)) }

        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Calendar.current.startOfDay(for: Date())) ?? .distantPast
        return all.filter { $0.date >= weekAgo }
    }

    private struct TimelineEntry: Identifiable {
        let id: String
        let date: Date
        let isSlip: Bool
        let title: String
        let detail: String?
    }
}
