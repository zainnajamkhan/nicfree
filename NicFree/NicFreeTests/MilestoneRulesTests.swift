import Foundation
import Testing

@testable import NicFree

/// Milestones count finished free days, so a day still in progress never earns one.
@Suite("Milestone rules")
struct MilestoneRulesTests {

    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        return calendar
    }()
    private let today = Date(timeIntervalSince1970: 1_755_000_000)

    private func day(_ daysAgo: Int) -> Date {
        calendar.date(byAdding: .day, value: -daysAgo, to: calendar.startOfDay(for: today))!
    }

    private func stats(startedDaysAgo: Int, usedDaysAgo: [Int] = []) -> QuitStats {
        QuitStats(quitStartedAt: day(startedDaysAgo), usedDays: Set(usedDaysAgo.map(day)), today: today, calendar: calendar)
    }

    @Test("Today never counts as finished")
    func todayIsNotFinished() {
        #expect(stats(startedDaysAgo: 0).finishedFreeDays == 0)
        #expect(stats(startedDaysAgo: 6).finishedFreeDays == 6)
        #expect(stats(startedDaysAgo: 6).lifetimeFreeDays == 7)
    }

    @Test("A slip today leaves finished days alone")
    func slipTodayKeepsFinished() {
        let withSlip = stats(startedDaysAgo: 6, usedDaysAgo: [0])
        #expect(withSlip.todayIsUsed)
        #expect(withSlip.finishedFreeDays == 6)
    }

    @Test("A slip yesterday lowers finished days by one")
    func slipYesterday() {
        #expect(stats(startedDaysAgo: 6, usedDaysAgo: [1]).finishedFreeDays == 5)
    }

    @Test("Seven free days finishing tonight are announced tomorrow morning")
    func announcedMorningAfter() {
        // Six finished days, today free: today is the seventh, so the note is due tomorrow.
        let offsets = MilestoneScheduler.announcementOffsets(finishedFreeDays: 6, todayUsed: false)
        #expect(offsets[7] == 1)
        #expect(offsets[3] == nil)
    }

    @Test("A slip today pushes everything a day later")
    func slipPushesBack() {
        let offsets = MilestoneScheduler.announcementOffsets(finishedFreeDays: 6, todayUsed: true)
        #expect(offsets[7] == 2)
    }

    @Test("Nothing is ever scheduled for today")
    func neverInThePast() {
        for finished in 0...400 {
            for used in [false, true] {
                let offsets = MilestoneScheduler.announcementOffsets(finishedFreeDays: finished, todayUsed: used)
                #expect(offsets.values.allSatisfy { $0 >= 1 })
            }
        }
    }
}
