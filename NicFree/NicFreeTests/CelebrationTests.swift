import Foundation
import Testing

@testable import NicFree

/// A fixed UTC calendar and instant, like the catch-up tests, so these never flake.
@Suite("Celebration")
struct CelebrationTests {

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

    private func gained(lastCelebrated: Int, quit: Int = 100, used: [Int] = []) -> Int {
        Celebration.newFreeDays(
            lastCelebrated: day(lastCelebrated),
            quitStartedAt: day(quit),
            usedDays: Set(used.map(day)),
            today: today,
            calendar: calendar
        )
    }

    @Test("Opening again the same day celebrates nothing")
    func sameDayIsQuiet() {
        #expect(gained(lastCelebrated: 1) == 0)
    }

    @Test("A new day celebrates yesterday, never today")
    func celebratesYesterdayOnly() {
        #expect(gained(lastCelebrated: 2) == 1)
    }

    @Test("Days away are celebrated together, minus any slips")
    func daysAwayAddUp() {
        #expect(gained(lastCelebrated: 5) == 4)
        #expect(gained(lastCelebrated: 5, used: [3]) == 3)
        #expect(gained(lastCelebrated: 2, used: [1]) == 0)
    }

    @Test("Days before the quit date never count")
    func notBeforeQuitting() {
        #expect(gained(lastCelebrated: 10, quit: 2) == 2)
    }

    @Test("The biggest milestone passed is the one shown")
    func milestones() {
        #expect(Celebration.milestone(from: 6, to: 7) == 7)
        #expect(Celebration.milestone(from: 59, to: 63) == 60)
        #expect(Celebration.milestone(from: 0, to: 8) == 7)
        #expect(Celebration.milestone(from: 7, to: 8) == nil)
    }
}
