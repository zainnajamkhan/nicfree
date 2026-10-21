//
//  CravingInsights.swift
//  NicFree
//

import Foundation

/// Pure analysis over craving history.
///
/// No SwiftData and no SwiftUI, so it is directly testable and shared unchanged by the
/// daily observation line, the History screen and the paid Insights screen. None of them
/// owns the arithmetic.
struct CravingInsights {

    /// A craving reduced to what the maths needs. Deliberately not the `@Model` type.
    struct Event: Equatable {
        let occurredAt: Date
        let heldOutSeconds: Int
        let resisted: Bool
        let trigger: String?
    }

    let events: [Event]
    var calendar: Calendar = .current

    init(events: [Event], calendar: Calendar = .current) {
        // Oldest first, so week windows and "the last n" read the same way everywhere.
        self.events = events.sorted { $0.occurredAt < $1.occurredAt }
        self.calendar = calendar
    }

    // MARK: - Totals

    var count: Int { events.count }

    var resistedCount: Int { events.filter(\.resisted).count }

    /// Only cravings that were ridden out. Averaging in the ones that ended in use would
    /// drag the figure down and make the number less useful at the moment it is needed.
    var averageHeldOutSeconds: Int {
        let held = events.filter(\.resisted)
        guard !held.isEmpty else { return 0 }
        return held.reduce(0) { $0 + $1.heldOutSeconds } / held.count
    }

    /// Counts every craving, including those that ended in use. Sitting with it for six
    /// minutes and then vaping is still six minutes of effort.
    ///
    /// Like the hero number, this can only grow.
    var totalHeldOutSeconds: Int {
        events.reduce(0) { $0 + $1.heldOutSeconds }
    }

    var longestHeldOutSeconds: Int {
        events.filter(\.resisted).map(\.heldOutSeconds).max() ?? 0
    }

    /// How many of the most recent cravings were ridden out.
    func resistedOfLast(_ n: Int) -> (resisted: Int, total: Int) {
        let recent = events.suffix(n)
        return (recent.filter(\.resisted).count, recent.count)
    }

    // MARK: - Patterns

    var topTrigger: (trigger: String, count: Int)? {
        let counts = events.compactMap(\.trigger).reduce(into: [:]) { tally, trigger in
            tally[trigger, default: 0] += 1
        }
        guard let best = counts.max(by: { $0.value < $1.value }) else { return nil }
        return (best.key, best.value)
    }

    /// Every trigger with how often it came up, most frequent first. Ties break by name
    /// so the order is stable between launches.
    var triggerRanking: [(trigger: String, count: Int)] {
        let counts = events.compactMap(\.trigger).reduce(into: [String: Int]()) { tally, trigger in
            tally[trigger, default: 0] += 1
        }
        return counts
            .sorted { $0.value != $1.value ? $0.value > $1.value : $0.key < $1.key }
            .map { (trigger: $0.key, count: $0.value) }
    }

    /// The hour of day most cravings arrive in, as a 0 to 23 value.
    var riskiestHour: Int? {
        let counts = events.reduce(into: [Int: Int]()) { tally, event in
            tally[calendar.component(.hour, from: event.occurredAt), default: 0] += 1
        }
        return counts.max(by: { $0.value < $1.value })?.key
    }

    // MARK: - Trend

    /// Cravings in the seven days following the first one logged.
    func firstWeekCount() -> Int {
        guard let first = events.first?.occurredAt else { return 0 }
        let start = calendar.startOfDay(for: first)
        guard let end = calendar.date(byAdding: .day, value: 7, to: start) else { return 0 }
        return events.filter { $0.occurredAt >= start && $0.occurredAt < end }.count
    }

    /// Cravings in the seven days before today.
    func lastWeekCount(endingOn today: Date = Date()) -> Int {
        let end = calendar.startOfDay(for: today)
        guard let start = calendar.date(byAdding: .day, value: -7, to: end) else { return 0 }
        return events.filter { $0.occurredAt >= start && $0.occurredAt < end }.count
    }

    /// Cravings per week for the chart and the trend line, oldest first.
    func weeklyCounts(endingOn today: Date = Date(), weeks: Int = 12) -> [(weekStart: Date, count: Int)] {
        let end = calendar.startOfDay(for: today)
        var result: [(Date, Int)] = []

        for offset in stride(from: weeks - 1, through: 0, by: -1) {
            guard
                let start = calendar.date(byAdding: .day, value: -7 * (offset + 1), to: end),
                let finish = calendar.date(byAdding: .day, value: 7, to: start)
            else { continue }

            let count = events.filter { $0.occurredAt >= start && $0.occurredAt < finish }.count
            result.append((start, count))
        }

        return result
    }
}
