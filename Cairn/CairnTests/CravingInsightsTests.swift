import Foundation
import Testing

@testable import Cairn

/// Fixed UTC calendar and a fixed instant, so nothing flakes on a timezone change, a DST
/// boundary or the machine's locale.
@Suite("Craving insights")
struct CravingInsightsTests {

    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        return calendar
    }()

    private let today = Date(timeIntervalSince1970: 1_755_000_000)

    private func moment(daysAgo: Int, hour: Int = 12) -> Date {
        let start = calendar.startOfDay(for: today)
        let day = calendar.date(byAdding: .day, value: -daysAgo, to: start) ?? start
        return calendar.date(byAdding: .hour, value: hour, to: day) ?? day
    }

    private func event(
        daysAgo: Int,
        hour: Int = 12,
        held: Int = 120,
        resisted: Bool = true,
        trigger: String? = nil
    ) -> CravingInsights.Event {
        CravingInsights.Event(
            occurredAt: moment(daysAgo: daysAgo, hour: hour),
            heldOutSeconds: held,
            resisted: resisted,
            trigger: trigger
        )
    }

    private func insights(_ events: [CravingInsights.Event]) -> CravingInsights {
        CravingInsights(events: events, calendar: calendar)
    }

    // MARK: - Totals

    @Test("Triggers rank by count, ties broken by name, untagged cravings ignored")
    func triggerRankingOrder() {
        let subject = insights([
            event(daysAgo: 4, trigger: "stress"),
            event(daysAgo: 3, trigger: "phone"),
            event(daysAgo: 2, trigger: "phone"),
            event(daysAgo: 2, trigger: "coffee"),
            event(daysAgo: 1)
        ])

        #expect(subject.triggerRanking.map(\.trigger) == ["phone", "coffee", "stress"])
        #expect(subject.triggerRanking.map(\.count) == [2, 1, 1])
    }

    @Test("The average covers only cravings that were ridden out")
    func averageExcludesGivenIn() {
        let subject = insights([
            event(daysAgo: 3, held: 100),
            event(daysAgo: 2, held: 200),
            event(daysAgo: 1, held: 6, resisted: false)
        ])

        #expect(subject.averageHeldOutSeconds == 150)
    }

    @Test("Total time held out counts every craving, including the ones that ended in use")
    func totalCountsEffortRegardless() {
        let subject = insights([
            event(daysAgo: 2, held: 100),
            event(daysAgo: 1, held: 360, resisted: false)
        ])

        // Sitting with it for six minutes and then vaping is still six minutes of effort.
        #expect(subject.totalHeldOutSeconds == 460)
    }

    @Test("Total time held out can only grow as cravings are added")
    func totalIsMonotonic() {
        let before = insights([event(daysAgo: 2, held: 100)])
        let after = insights([
            event(daysAgo: 2, held: 100),
            event(daysAgo: 1, held: 30, resisted: false)
        ])

        #expect(after.totalHeldOutSeconds >= before.totalHeldOutSeconds)
    }

    @Test("The longest hold ignores cravings that ended in use")
    func longestIgnoresGivenIn() {
        let subject = insights([
            event(daysAgo: 2, held: 300),
            event(daysAgo: 1, held: 900, resisted: false)
        ])

        #expect(subject.longestHeldOutSeconds == 300)
    }

    @Test("Recent outcomes are counted from the newest events")
    func recentOutcomes() {
        var events = (1...10).map { event(daysAgo: 20 - $0, resisted: false) }
        events += (1...3).map { event(daysAgo: 3 - $0) }

        let recent = insights(events).resistedOfLast(5)

        #expect(recent.total == 5)
        #expect(recent.resisted == 3)
    }

    // MARK: - Patterns

    @Test("The top trigger is the most frequent one")
    func topTrigger() {
        let subject = insights([
            event(daysAgo: 5, trigger: "phone"),
            event(daysAgo: 4, trigger: "phone"),
            event(daysAgo: 3, trigger: "phone"),
            event(daysAgo: 2, trigger: "stress"),
            event(daysAgo: 1, trigger: nil)
        ])

        #expect(subject.topTrigger?.trigger == "phone")
        #expect(subject.topTrigger?.count == 3)
    }

    @Test("With no triggers recorded there is no top trigger")
    func noTriggers() {
        #expect(insights([event(daysAgo: 1)]).topTrigger == nil)
    }

    @Test("The riskiest hour is the most common hour of day")
    func riskiestHour() {
        let subject = insights([
            event(daysAgo: 4, hour: 21),
            event(daysAgo: 3, hour: 21),
            event(daysAgo: 2, hour: 9)
        ])

        #expect(subject.riskiestHour == 21)
    }

    // MARK: - Trend

    @Test("The frequency trend compares the first week against the last")
    func frequencyTrend() {
        // Four in the first week, one in the last: the decay this app is built to show.
        var events = [
            event(daysAgo: 30),
            event(daysAgo: 29),
            event(daysAgo: 28),
            event(daysAgo: 25)
        ]
        events.append(event(daysAgo: 3))

        let subject = insights(events)

        #expect(subject.firstWeekCount() == 4)
        #expect(subject.lastWeekCount(endingOn: today) == 1)
    }

    @Test("Weekly counts return one bucket per week, oldest first")
    func weeklyBuckets() {
        let subject = insights([event(daysAgo: 2), event(daysAgo: 1)])
        let weeks = subject.weeklyCounts(endingOn: today, weeks: 4)

        #expect(weeks.count == 4)
        #expect(weeks.last?.count == 2)
        #expect(weeks.first?.count == 0)
    }

    @Test("An empty history produces no crashes and no claims")
    func emptyHistory() {
        let subject = insights([])

        #expect(subject.count == 0)
        #expect(subject.averageHeldOutSeconds == 0)
        #expect(subject.longestHeldOutSeconds == 0)
        #expect(subject.topTrigger == nil)
        #expect(subject.riskiestHour == nil)
        #expect(subject.firstWeekCount() == 0)
    }
}
