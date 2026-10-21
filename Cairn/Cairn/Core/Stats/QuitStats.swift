import Foundation

/// Every number the app displays, derived from a single input: the set of days on
/// which nicotine was used.
///
/// Deliberately free of any SwiftData dependency so it can be tested directly. This
/// is the only part of the app with real unit tests, because the hero number being
/// wrong once would destroy trust in everything else.
struct QuitStats {
    let quitStartedAt: Date
    /// Normalised to start of day. Membership means nicotine was used that day.
    let usedDays: Set<Date>
    let today: Date
    var calendar: Calendar = .current

    init(
        quitStartedAt: Date,
        usedDays: Set<Date>,
        today: Date = Date(),
        calendar: Calendar = .current
    ) {
        self.quitStartedAt = quitStartedAt
        self.usedDays = usedDays
        self.today = today
        self.calendar = calendar
    }

    // MARK: - Range

    private var endDay: Date { calendar.startOfDay(for: today) }

    /// Clamped so that a start date in the future cannot produce a negative span.
    private var startDay: Date { min(calendar.startOfDay(for: quitStartedAt), endDay) }

    private var usedDaysTracked: Set<Date> {
        usedDays.filter { $0 >= startDay && $0 <= endDay }
    }

    /// Days elapsed since quitting, counting today. Never less than one.
    var totalDaysTracked: Int {
        let span = calendar.dateComponents([.day], from: startDay, to: endDay).day ?? 0
        return max(1, span + 1)
    }

    // MARK: - The hero number

    /// Total days without nicotine since quitting.
    ///
    /// This is the number the whole app is built around, and it cannot decrease. A
    /// slip adds a used day; it never removes a free one. As time passes this only
    /// ever grows, which is the entire point.
    var lifetimeFreeDays: Int {
        max(0, totalDaysTracked - usedDaysTracked.count)
    }

    var usedDayCount: Int { usedDaysTracked.count }

    /// Share of tracked days that were free, for the year grid summary.
    var freeDayRatio: Double {
        guard totalDaysTracked > 0 else { return 0 }
        return Double(lifetimeFreeDays) / Double(totalDaysTracked)
    }

    // MARK: - Runs

    /// Consecutive free days ending today. Deliberately the small number on screen:
    /// it resets, so it must never be what the user feels they are protecting.
    var currentRun: Int {
        let used = usedDaysTracked
        var count = 0
        var cursor = endDay

        while cursor >= startDay, !used.contains(cursor) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return count
    }

    /// Longest free stretch ever achieved. Survives every later slip, so it stands
    /// as proof the user has already done the hard thing once.
    var longestRun: Int {
        let used = usedDaysTracked
        var longest = 0
        var run = 0
        var cursor = startDay

        while cursor <= endDay {
            if used.contains(cursor) {
                run = 0
            } else {
                run += 1
                longest = max(longest, run)
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return longest
    }

    // MARK: - Estimates

    /// Estimates, not accounting, so `Double` is appropriate. Always displayed rounded.
    func moneySaved(dailyCost: Double) -> Double {
        Double(lifetimeFreeDays) * dailyCost
    }

    func nicotineAvoidedMg(dailyMg: Double) -> Double {
        Double(lifetimeFreeDays) * dailyMg
    }
}
