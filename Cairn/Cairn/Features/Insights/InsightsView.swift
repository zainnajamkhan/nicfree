//
//  InsightsView.swift
//  Cairn
//

import SwiftUI
import SwiftData
import Charts

/// Personal evidence instead of generic reassurance: their cravings, their triggers,
/// their hours. Every number comes from `CravingInsights`; this view only lays it out.
///
/// The paid screen. Locked, it says what is inside and offers the unlock once.
struct InsightsView: View {
    @Environment(PurchaseStore.self) private var store
    @Query(sort: \CravingEvent.occurredAt) private var cravings: [CravingEvent]

    @State private var showingPaywall = false

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

    var body: some View {
        Screen {
            ScrollView {
                VStack(alignment: .leading, spacing: Space.m) {
                    if !store.isUnlocked {
                        LockedCard(
                            title: "Insights",
                            detail: "What sets your cravings off, the hours they arrive, how long they last, and how often they come each week."
                        ) { showingPaywall = true }
                    } else if insights.count == 0 {
                        empty
                    } else {
                        cravingsCard
                        triggersCard
                        hourCard
                        weeklyCard
                    }
                }
                .padding(.vertical, Space.m)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .navigationTitle("Insights")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingPaywall) { PaywallView() }
    }

    // MARK: - Cards

    private var empty: some View {
        card("Nothing to read yet") {
            Text("Insights fill in as cravings are logged. Next time one comes, tap I'm having a craving.")
                .font(Typeface.row)
                .foregroundStyle(Palette.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var cravingsCard: some View {
        let recent = insights.resistedOfLast(12)

        return card("Your cravings") {
            HStack(alignment: .firstTextBaseline, spacing: Space.l) {
                figure(duration(insights.averageHeldOutSeconds), "average length")
                figure("\(recent.resisted) of \(recent.total)", "recent ones ridden out")
            }
            Text("Average length counts the ones you rode out.")
                .font(.caption)
                .foregroundStyle(Palette.inkFaint)
        }
    }

    @ViewBuilder
    private var triggersCard: some View {
        let ranking = insights.triggerRanking
        if !ranking.isEmpty {
            let top = ranking.first?.count ?? 1
            card("What sets them off") {
                VStack(spacing: Space.s + 2) {
                    ForEach(ranking.prefix(6), id: \.trigger) { item in
                        HStack(spacing: Space.s) {
                            Text(name(of: item.trigger))
                                .font(Typeface.row)
                                .foregroundStyle(Palette.ink)
                                .frame(width: 130, alignment: .leading)
                            GeometryReader { proxy in
                                Capsule()
                                    .fill(Palette.sky)
                                    .frame(width: max(10, proxy.size.width * Double(item.count) / Double(top)))
                            }
                            .frame(height: 12)
                            Text(item.count.formatted())
                                .font(Typeface.row)
                                .foregroundStyle(Palette.inkSoft)
                                .monospacedDigit()
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(name(of: item.trigger)), \(item.count)")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var hourCard: some View {
        if let hour = insights.riskiestHour {
            card("When they come") {
                Text("Most arrive around \(hourLabel(hour)).")
                    .font(Typeface.voice)
                    .foregroundStyle(Palette.ink)
                Text("Worth having a plan for that hour.")
                    .font(Typeface.row)
                    .foregroundStyle(Palette.inkSoft)
            }
        }
    }

    private var weeklyCard: some View {
        let weeks = insights.weeklyCounts(weeks: 8)

        return card("Each week") {
            Chart(weeks, id: \.weekStart) { week in
                BarMark(
                    x: .value("Week", week.weekStart, unit: .weekOfYear),
                    y: .value("Cravings", week.count)
                )
                .foregroundStyle(Palette.leaf)
                .cornerRadius(6)
            }
            .chartYAxis {
                AxisMarks(position: .leading) {
                    AxisGridLine().foregroundStyle(Palette.hairline)
                    AxisValueLabel().foregroundStyle(Palette.inkFaint)
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .weekOfYear, count: 2)) {
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                        .foregroundStyle(Palette.inkFaint)
                }
            }
            .frame(height: 160)
            .accessibilityLabel("Cravings per week, last eight weeks")
        }
    }

    // MARK: - Pieces

    private func card<Content: View>(_ title: LocalizedStringKey, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Space.m) {
            SectionLabel(title)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Space.m + 4)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card)
                .stroke(Palette.hairline, lineWidth: 2)
        )
    }

    private func figure(_ value: String, _ caption: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(Typeface.hero(30))
                .foregroundStyle(Palette.ink)
            Text(caption)
                .font(.caption)
                .foregroundStyle(Palette.inkSoft)
        }
        .accessibilityElement(children: .combine)
    }

    private func duration(_ seconds: Int) -> String {
        Duration.seconds(seconds).formatted(.units(allowed: [.minutes, .seconds], width: .narrow))
    }

    private func name(of raw: String) -> String {
        CravingTrigger(rawValue: raw).map { String(localized: $0.title) } ?? raw
    }

    private func hourLabel(_ hour: Int) -> String {
        var components = DateComponents()
        components.hour = hour
        let date = Calendar.current.date(from: components) ?? Date()
        return date.formatted(.dateTime.hour())
    }
}

#Preview {
    NavigationStack { InsightsView() }
        .environment(PurchaseStore())
        .modelContainer(for: [Habit.self, DayRecord.self, CravingEvent.self], inMemory: true)
}
