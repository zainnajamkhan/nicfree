//
//  QuitStatsSeries.swift
//  NicFree
//

import Foundation

extension QuitStats {

    /// One day of the record, carrying both its state and the running total as at that
    /// day. The year grid and the cumulative chart both read this, so there is exactly
    /// one definition of what happened on any given date.
    struct DayPoint: Identifiable, Equatable {
        let date: Date
        let wasUsed: Bool
        let cumulativeFreeDays: Int

        var id: Date { date }
    }

    /// Day by day from the quit date to today, oldest first.
    ///
    /// The cumulative figure only ever rises or holds flat. It cannot fall, which is the
    /// whole thesis drawn as a line.
    func series() -> [DayPoint] {
        let used = usedDays
        var points: [DayPoint] = []
        var running = 0

        var cursor = calendar.startOfDay(for: min(quitStartedAt, today))
        let last = calendar.startOfDay(for: today)

        while cursor <= last {
            let wasUsed = used.contains(cursor)
            if !wasUsed { running += 1 }

            points.append(
                DayPoint(date: cursor, wasUsed: wasUsed, cumulativeFreeDays: running)
            )

            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }

        return points
    }
}
