//
//  Celebration.swift
//  NicFree
//

import Foundation

/// Which newly finished free days Home celebrates when it opens.
///
/// A day is celebrated only once it's over and had no slip, and only once. A day still in
/// progress is never celebrated, so a slip logged tonight can't follow a party this morning.
enum Celebration {
    /// Off for now (2026-10-23): a full screen party can greet someone who opened the app to
    /// log a slip, possibly for the very day being celebrated. Home still keeps
    /// `lastCelebratedThrough` up to date, so turning this back on won't celebrate a backlog.
    /// The UI tests' launch flags turn it on in debug builds so the code stays tested.
    static var isEnabled: Bool {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        return arguments.contains("-celebrateForUITests") || arguments.contains("-celebrateMilestoneForUITests")
        #else
        return false
        #endif
    }

    /// Free days after `lastCelebrated`, up to and including yesterday.
    static func newFreeDays(
        lastCelebrated: Date,
        quitStartedAt: Date,
        usedDays: Set<Date>,
        today: Date = Date(),
        calendar: Calendar = .current
    ) -> Int {
        let todayStart = calendar.startOfDay(for: today)
        guard let afterLast = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: lastCelebrated)) else {
            return 0
        }
        var day = max(afterLast, calendar.startOfDay(for: quitStartedAt))
        var count = 0
        while day < todayStart {
            if !usedDays.contains(day) { count += 1 }
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return count
    }

    /// The biggest milestone passed going from `from` to `to` free days, if any.
    static func milestone(from: Int, to: Int, milestones: [Int] = MilestoneScheduler.milestones) -> Int? {
        milestones.filter { $0 > from && $0 <= to }.max()
    }
}
