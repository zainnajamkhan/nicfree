import Foundation
import Testing

@testable import Cairn

/// A fixed UTC calendar and a fixed instant, so these never flake on a timezone
/// change, a DST boundary, or the machine's locale.
@Suite("Quit stats")
struct QuitStatsTests {

    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        return calendar
    }()

    private let today = Date(timeIntervalSince1970: 1_755_000_000)

    private func day(_ daysAgo: Int) -> Date {
        let start = calendar.startOfDay(for: today)
        return calendar.date(byAdding: .day, value: -daysAgo, to: start) ?? start
    }

    private func stats(startedDaysAgo: Int, usedDaysAgo: [Int] = []) -> QuitStats {
        QuitStats(
            quitStartedAt: day(startedDaysAgo),
            usedDays: Set(usedDaysAgo.map(day)),
            today: today,
            calendar: calendar
        )
    }

    // MARK: - The hero number

    @Test("A clean run counts every day including today")
    func cleanRun() {
        let stats = stats(startedDaysAgo: 9)

        #expect(stats.totalDaysTracked == 10)
        #expect(stats.lifetimeFreeDays == 10)
        #expect(stats.currentRun == 10)
        #expect(stats.longestRun == 10)
    }

    @Test("Each slip costs exactly one free day and nothing else")
    func slipsCostOneDayEach() {
        let stats = stats(startedDaysAgo: 9, usedDaysAgo: [3, 7])

        #expect(stats.totalDaysTracked == 10)
        #expect(stats.lifetimeFreeDays == 8)
        #expect(stats.usedDayCount == 2)
    }

    @Test("The lifetime total never decreases as time passes")
    func lifetimeTotalIsMonotonic() {
        let now = stats(startedDaysAgo: 9, usedDaysAgo: [3])
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today
        let later = QuitStats(
            quitStartedAt: day(9),
            usedDays: [day(3)],
            today: tomorrow,
            calendar: calendar
        )

        #expect(later.lifetimeFreeDays >= now.lifetimeFreeDays)
        #expect(later.lifetimeFreeDays == now.lifetimeFreeDays + 1)
    }

    @Test("Vaping today resets the run but leaves the lifetime total standing")
    func slipTodayDoesNotTouchLifetimeTotal() {
        let stats = stats(startedDaysAgo: 9, usedDaysAgo: [0])

        #expect(stats.currentRun == 0)
        #expect(stats.lifetimeFreeDays == 9)
        #expect(stats.longestRun == 9)
    }

    // MARK: - Runs

    @Test("The longest run survives a later slip")
    func longestRunSurvivesLaterSlip() {
        // Free on days 9 through 5, used on day 4, free on days 3 through 0.
        let stats = stats(startedDaysAgo: 9, usedDaysAgo: [4])

        #expect(stats.longestRun == 5)
        #expect(stats.currentRun == 4)
        #expect(stats.lifetimeFreeDays == 9)
    }

    @Test("Consecutive slips do not compound the damage")
    func consecutiveSlips() {
        let stats = stats(startedDaysAgo: 9, usedDaysAgo: [5, 4, 3])

        #expect(stats.lifetimeFreeDays == 7)
        #expect(stats.currentRun == 3)
        #expect(stats.longestRun == 4)
    }

    // MARK: - Edges

    @Test("Days recorded before the quit date are ignored")
    func daysOutsideRangeIgnored() {
        let stats = stats(startedDaysAgo: 5, usedDaysAgo: [20])

        #expect(stats.totalDaysTracked == 6)
        #expect(stats.lifetimeFreeDays == 6)
        #expect(stats.usedDayCount == 0)
    }

    @Test("A quit date in the future cannot produce a negative span")
    func futureQuitDateClamps() {
        let stats = stats(startedDaysAgo: -5)

        #expect(stats.totalDaysTracked == 1)
        #expect(stats.lifetimeFreeDays >= 0)
    }

    @Test("Quitting today reads as one free day, not zero")
    func firstDayCounts() {
        let stats = stats(startedDaysAgo: 0)

        #expect(stats.lifetimeFreeDays == 1)
        #expect(stats.currentRun == 1)
    }

    // MARK: - Estimates

    @Test("Savings scale with free days, not elapsed days")
    func savingsFollowFreeDays() {
        let clean = stats(startedDaysAgo: 9)
        let withSlips = stats(startedDaysAgo: 9, usedDaysAgo: [2, 6])

        #expect(clean.moneySaved(dailyCost: 12.5) == 125)
        #expect(withSlips.moneySaved(dailyCost: 12.5) == 100)
    }

    @Test("Nicotine avoided follows the same rule")
    func nicotineAvoided() {
        let stats = stats(startedDaysAgo: 9, usedDaysAgo: [1])

        #expect(stats.nicotineAvoidedMg(dailyMg: 20) == 180)
    }
}
