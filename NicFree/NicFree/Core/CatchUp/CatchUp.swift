//
//  CatchUp.swift
//  NicFree
//

import Foundation

/// Which days to ask about when someone comes back after time away.
///
/// There is no required check-in: a day without a record is free. But a slip that happened
/// while the app stayed closed could never be recorded, so on return the app asks about the
/// days it did not see, from the last day it was opened up to yesterday. Today is excluded
/// because it is not over.
enum CatchUp {

    /// Asking about two months of days one chip at a time is not a question anyone answers.
    static let maximumDays = 14

    /// Empty unless at least one whole day went by unseen, so daily users are never asked.
    static func daysToAsk(
        lastChecked: Date?,
        quitStartedAt: Date,
        alreadyUsed: Set<Date>,
        today: Date = Date(),
        calendar: Calendar = .current
    ) -> [Date] {
        guard let lastChecked else { return [] }

        let todayStart = calendar.startOfDay(for: today)
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: todayStart) else { return [] }

        let start = calendar.startOfDay(for: max(lastChecked, quitStartedAt))
        guard start < yesterday else { return [] }

        let earliest = calendar.date(byAdding: .day, value: -(maximumDays - 1), to: yesterday) ?? start
        var cursor = max(start, earliest)
        var days: [Date] = []
        while cursor <= yesterday {
            if !alreadyUsed.contains(cursor) { days.append(cursor) }
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return days
    }
}
