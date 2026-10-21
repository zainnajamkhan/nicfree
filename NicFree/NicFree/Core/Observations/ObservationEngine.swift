//
//  ObservationEngine.swift
//  NicFree
//

import Foundation

/// One factual line drawn from the user's own data, shown beneath the hero number.
///
/// Named `DailyObservation` rather than `Observation` on purpose: `Observation` is a
/// standard library *module*, and SwiftData's `@Model` macro expands to fully qualified
/// references such as `Observation.Observable`. A type of that name anywhere in the
/// module shadows it and breaks every `@Model` in the target.
struct DailyObservation: Equatable {
    let id: String
    let text: String
}

/// Every entry must pass a single test: **would this be acceptable to show on the day
/// the user relapsed?** A fact survives that test. Encouragement does not, and any line
/// whose motivating force is fear of losing something is banned outright.
enum ObservationEngine {

    static func daily(
        stats: QuitStats,
        habit: Habit,
        cravings: CravingInsights,
        on date: Date = Date(),
        calendar: Calendar = .current
    ) -> DailyObservation? {
        let candidates = eligible(stats: stats, habit: habit, cravings: cravings, on: date)
        guard !candidates.isEmpty else { return nil }

        // Seeded by the day, so the line is stable for the whole day and identical in the
        // app, on the widget and in the notification. A line that reshuffles on every
        // launch reads as random and stops being believed.
        let dayNumber = calendar.ordinality(of: .day, in: .era, for: date) ?? 0
        return candidates[dayNumber % candidates.count]
    }

    static func eligible(
        stats: QuitStats,
        habit: Habit,
        cravings: CravingInsights,
        on date: Date = Date()
    ) -> [DailyObservation] {
        var result: [DailyObservation] = []

        // MARK: Available from day one

        let saved = stats.moneySaved(dailyCost: habit.baselineDailyCost)
        if saved >= 1 {
            let amount = saved.formatted(
                .currency(code: habit.currencyCode).precision(.fractionLength(0))
            )
            result.append(
                DailyObservation(
                    id: "money",
                    text: String(localized: "\(amount) has stayed in your account.")
                )
            )
        }

        // On a bad day this is the most useful sentence in the app: proof of capability
        // rather than praise.
        if stats.longestRun > stats.currentRun, stats.longestRun >= 2 {
            result.append(
                DailyObservation(
                    id: "longestRun",
                    text: String(localized: "Your longest run was \(stats.longestRun) days. You have already done this once.")
                )
            )
        }

        // MARK: Needs a week of history

        if stats.totalDaysTracked >= 7 {
            result.append(
                DailyObservation(
                    id: "ratio",
                    text: String(localized: "\(stats.lifetimeFreeDays) of your last \(stats.totalDaysTracked) days had no nicotine in them.")
                )
            )
        }

        // MARK: Needs five cravings

        if cravings.count >= 5 {
            if cravings.averageHeldOutSeconds > 0 {
                result.append(
                    DailyObservation(
                        id: "averageHold",
                        text: String(localized: "Your cravings last \(shortDuration(cravings.averageHeldOutSeconds)) on average.")
                    )
                )
            }

            let recent = cravings.resistedOfLast(12)
            if recent.resisted > 0 {
                result.append(
                    DailyObservation(
                        id: "resistedRatio",
                        text: String(localized: "You rode out \(recent.resisted) of your last \(recent.total) cravings.")
                    )
                )
            }

            if cravings.totalHeldOutSeconds >= 600 {
                result.append(
                    DailyObservation(
                        id: "totalHold",
                        text: String(localized: "You have waited out \(longDuration(cravings.totalHeldOutSeconds)) of cravings in total.")
                    )
                )
            }

            if cravings.longestHeldOutSeconds >= 120 {
                result.append(
                    DailyObservation(
                        id: "longestHold",
                        text: String(localized: "The longest craving you have ridden out lasted \(shortDuration(cravings.longestHeldOutSeconds)).")
                    )
                )
            }
        }

        // MARK: Needs a fortnight and eight cravings

        if stats.totalDaysTracked >= 14, cravings.count >= 8 {
            // The best statistic in the app. Craving frequency genuinely decays, so this
            // is evidence the thing is working, and nobody argues with their own trend.
            let first = cravings.firstWeekCount()
            let last = cravings.lastWeekCount(endingOn: date)
            if first > last {
                result.append(
                    DailyObservation(
                        id: "trend",
                        text: String(localized: "Your cravings have dropped from \(first) in your first week to \(last) last week.")
                    )
                )
            }

            if let top = cravings.topTrigger,
               let trigger = CravingTrigger(rawValue: top.trigger),
               top.count >= 3 {
                let name = String(localized: trigger.title).lowercased()
                result.append(
                    DailyObservation(
                        id: "topTrigger",
                        text: String(localized: "\"\(name)\" accounts for \(top.count) of your cravings, more than anything else.")
                    )
                )
            }

            if let hour = cravings.riskiestHour {
                result.append(
                    DailyObservation(
                        id: "riskyHour",
                        text: String(localized: "Most of your cravings arrive around \(hourLabel(hour)).")
                    )
                )
            }
        }

        return result
    }

    // MARK: - Formatting

    /// "4m 12s"
    private static func shortDuration(_ seconds: Int) -> String {
        Duration.seconds(seconds).formatted(
            .units(allowed: [.minutes, .seconds], width: .narrow)
        )
    }

    /// "3 hours, 40 minutes"
    private static func longDuration(_ seconds: Int) -> String {
        Duration.seconds(seconds).formatted(
            .units(allowed: [.hours, .minutes], width: .wide)
        )
    }

    private static func hourLabel(_ hour: Int) -> String {
        var components = DateComponents()
        components.hour = hour
        let date = Calendar.current.date(from: components) ?? Date()
        return date.formatted(.dateTime.hour())
    }
}
