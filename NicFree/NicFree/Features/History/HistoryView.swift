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
    /// A slip tapped in Events, opened to edit or remove.
    @State private var editingSlip: DayRecord?
    /// The date under the finger on the chart, nil when it isn't being touched.
    @State private var chartSelection: Date?

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
                                detail: "See every day since you stopped, plus your total over time. Your last 7 days are below."
                            ) { showingPaywall = true }
                            .padding(.top, Space.m)
                        }
                        timelineSection
                    }
                    .padding(.horizontal, Space.l)
                    .frame(maxWidth: ContentWidth.readable)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, Space.xxl)
                }
            }
        }
        .sheet(isPresented: $showingPaywall) { PaywallView() }
        .sheet(item: $editingSlip) { record in
            SlipLogView(existing: record, day: record.day)
                .presentationDetents([.medium, .large])
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .tint(Palette.accent)
    }

    // MARK: - Grid

    private func gridSection(_ stats: QuitStats) -> some View {
        VStack(alignment: .leading, spacing: Space.m) {
            SectionLabel("Every day since you stopped")

            VStack(alignment: .leading, spacing: Space.m) {
                YearGridLegend()
                YearGrid(points: stats.series())
            }
            .card()

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
    /// argued. Touch or drag to read any day; it stays picked after lifting the finger.
    private func chartSection(_ stats: QuitStats) -> some View {
        let points = stats.series()
        let dots = Self.dots(in: points)
        let selected = chartSelection.flatMap { date in points.first { $0.date == date } }
        let shown = selected ?? points.last

        return VStack(alignment: .leading, spacing: Space.m) {
            SectionLabel("Your total, over time")

            VStack(alignment: .leading, spacing: Space.m) {
                if let shown {
                    HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(inflecting: "^[\(shown.cumulativeFreeDays) free day](inflect: true)"))
                            .font(Typeface.voice)
                            .foregroundStyle(Palette.ink)
                            .contentTransition(.numericText(value: Double(shown.cumulativeFreeDays)))
                        Text(selected == nil
                             ? String(localized: "So far. Tap a dot to look back.")
                             : shown.date.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                            .font(.footnote)
                            .foregroundStyle(Palette.inkSoft)
                    }
                    .animation(.smooth(duration: 0.15), value: shown.cumulativeFreeDays)
                    Spacer()
                    if selected != nil {
                        Button("Back to today") { chartSelection = nil }
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Palette.accent)
                    }
                    }
                }

                Chart {
                    ForEach(points) { point in
                        AreaMark(
                            x: .value("Date", point.date),
                            y: .value("Days free", point.cumulativeFreeDays)
                        )
                        .foregroundStyle(
                            .linearGradient(
                                colors: [Palette.leaf.opacity(0.35), Palette.leaf.opacity(0.03)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.monotone)

                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Days free", point.cumulativeFreeDays)
                        )
                        .foregroundStyle(Palette.accent)
                        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                        .interpolationMethod(.monotone)

                        // A slip shows where the line held flat, in the same clay as the grid.
                        if point.wasUsed {
                            PointMark(
                                x: .value("Date", point.date),
                                y: .value("Days free", point.cumulativeFreeDays)
                            )
                            .foregroundStyle(Palette.clay)
                            .symbol(.square)
                            .symbolSize(40)
                        }
                    }

                    // The dots that can be tapped. Nothing else on the chart responds to touch.
                    ForEach(dots) { dot in
                        if !dot.wasUsed {
                            PointMark(
                                x: .value("Date", dot.date),
                                y: .value("Days free", dot.cumulativeFreeDays)
                            )
                            .foregroundStyle(Palette.accent.opacity(0.55))
                            .symbolSize(34)
                        }
                    }

                    if let shown {
                        if selected != nil {
                            RuleMark(x: .value("Date", shown.date))
                                .foregroundStyle(Palette.hairline)
                                .lineStyle(StrokeStyle(lineWidth: 2))
                        }
                        PointMark(
                            x: .value("Date", shown.date),
                            y: .value("Days free", shown.cumulativeFreeDays)
                        )
                        .foregroundStyle(Palette.accent)
                        .symbolSize(110)
                    }
                }
                // Only a tap on a dot selects it, and only a tap: there's no drag, so
                // scrolling through the chart never picks anything.
                .chartOverlay { proxy in
                    GeometryReader { geometry in
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture { location in
                                guard let plotFrame = proxy.plotFrame else { return }
                                let origin = geometry[plotFrame].origin
                                let tap = CGPoint(x: location.x - origin.x, y: location.y - origin.y)
                                let hit = dots
                                    .compactMap { dot -> (QuitStats.DayPoint, CGFloat)? in
                                        guard let x = proxy.position(forX: dot.date),
                                              let y = proxy.position(forY: dot.cumulativeFreeDays) else { return nil }
                                        return (dot, hypot(x - tap.x, y - tap.y))
                                    }
                                    .filter { $0.1 <= Self.tapRadius }
                                    .min { $0.1 < $1.1 }
                                if let hit { chartSelection = hit.0.date }
                            }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) {
                        AxisGridLine().foregroundStyle(Palette.hairline)
                        AxisValueLabel().foregroundStyle(Palette.inkFaint)
                    }
                }
                .chartXAxis {
                    // One label per month; the default ticks can repeat a month name.
                    AxisMarks(values: .stride(by: .month)) {
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                            .foregroundStyle(Palette.inkFaint)
                    }
                }
                .frame(height: 190)
                .sensoryFeedback(.selection, trigger: selected?.date)
                .accessibilityLabel("Total days free over time")
                .accessibilityValue(String(inflecting: "^[\(stats.lifetimeFreeDays) day](inflect: true)"))
            }
            .card()
        }
    }

    /// How close a tap has to land to a dot to pick it, in points.
    private static let tapRadius: CGFloat = 24

    /// The days that get a dot: every slip, the latest day, and enough others to be
    /// tappable without crowding. Roughly one every few points of width.
    private static func dots(in points: [QuitStats.DayPoint]) -> [QuitStats.DayPoint] {
        guard !points.isEmpty else { return [] }
        let step = max(1, points.count / 18)
        return points.enumerated().compactMap { index, point in
            let isLast = index == points.count - 1
            return (point.wasUsed || isLast || (points.count - 1 - index) % step == 0) ? point : nil
        }
    }

    // MARK: - Timeline

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: Space.m) {
            SectionLabel("Events")

            if entries.isEmpty {
                Text("Nothing here yet. That’s a good thing!")
                    .font(Typeface.voiceSmall)
                    .foregroundStyle(Palette.inkFaint)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(entries) { entry in
                        row(entry)
                    }
                }
            }
        }
    }

    /// Slips open to edit or remove; cravings are just a record.
    @ViewBuilder
    private func row(_ entry: TimelineEntry) -> some View {
        if let record = entry.slip {
            Button { editingSlip = record } label: { rowContent(entry) }
                .buttonStyle(.plain)
                .accessibilityHint("Edit or remove this slip")
        } else {
            rowContent(entry)
        }
    }

    private func rowContent(_ entry: TimelineEntry) -> some View {
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

                if entry.slip != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Palette.inkFaint)
                }
            }
            .contentShape(Rectangle())
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
                detail: record.intensity.map { String(localized: $0.title) },
                slip: record
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
        guard !store.isUnlocked else { return all }

        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Calendar.current.startOfDay(for: Date())) ?? .distantPast
        return all.filter { $0.date >= weekAgo }
    }

    private struct TimelineEntry: Identifiable {
        let id: String
        let date: Date
        let isSlip: Bool
        let title: String
        let detail: String?
        var slip: DayRecord? = nil
    }
}

private extension View {
    /// The same outlined card as Home's sprout card.
    func card() -> some View {
        padding(Space.m + 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.card)
                    .strokeBorder(Palette.hairline, lineWidth: 2)
            )
    }
}
