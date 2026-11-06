import Foundation
import Testing

@testable import NicFree

/// A fixed UTC calendar and instant, like the stats tests, so these never flake.
@Suite("Catch-up")
struct CatchUpTests {

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

    private func ask(lastChecked: Date?, quit: Int = 100, used: [Int] = []) -> [Date] {
        CatchUp.daysToAsk(
            lastChecked: lastChecked,
            quitStartedAt: day(quit),
            alreadyUsed: Set(used.map(day)),
            today: today,
            calendar: calendar
        )
    }

    @Test("Opening every day never asks anything")
    func dailyUserIsNeverAsked() {
        #expect(ask(lastChecked: day(0)).isEmpty)
        #expect(ask(lastChecked: day(1)).isEmpty)
    }

    @Test("Back after a full day away asks about the last day seen and every day since, not today")
    func asksFromLastSeenToYesterday() {
        #expect(ask(lastChecked: day(2)) == [day(2), day(1)])
        #expect(ask(lastChecked: day(4)) == [day(4), day(3), day(2), day(1)])
    }

    @Test("Days already logged as used are not asked about again")
    func skipsDaysAlreadyLogged() {
        #expect(ask(lastChecked: day(3), used: [2]) == [day(3), day(1)])
    }

    @Test("Never asks about days before the quit date")
    func respectsQuitDate() {
        #expect(ask(lastChecked: day(10), quit: 3) == [day(3), day(2), day(1)])
    }

    @Test("A long absence asks about the last two weeks only")
    func capsLongAbsences() {
        let days = ask(lastChecked: day(60))
        #expect(days.count == CatchUp.maximumDays)
        #expect(days.last == day(1))
    }

    @Test("No record of a last visit means nothing to ask yet")
    func firstLaunchAsksNothing() {
        #expect(ask(lastChecked: nil).isEmpty)
    }
}
