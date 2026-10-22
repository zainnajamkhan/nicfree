//
//  ScreenshotData.swift
//  NicFree
//

#if DEBUG
import Foundation
import SwiftData

/// A believable history for App Store screenshots: a pouch user 63 free days in, two slips,
/// and 38 cravings that thin out over time. DEBUG only, loaded with `-seedScreenshotData`.
enum ScreenshotData {

    static func seed(into context: ModelContext, now: Date = Date()) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        func day(_ daysAgo: Int) -> Date {
            calendar.date(byAdding: .day, value: -daysAgo, to: today) ?? today
        }

        context.insert(
            Habit(
                form: .pouch,
                unit: .pouch,
                baselineUnitsPerWeek: 56,
                costPerUnit: 0.45,
                nicotineMgPerUnit: ConsumptionUnit.pouch.defaultNicotineMg,
                currencyCode: "USD",
                quitStartedAt: day(64),
                reasons: [
                    "So I can climb stairs without stopping",
                    "The money",
                    "I do not want to need it"
                ]
            )
        )

        // 65 days tracked, two used, so the hero reads 63 and the next milestone is 90.
        context.insert(DayRecord(day: day(41), intensity: .fewPuffs))
        context.insert(DayRecord(day: day(12), intensity: .several))

        let triggers: [CravingTrigger] = [
            .phone, .phone, .afterMeal, .stress, .phone, .coffee, .boredom,
            .phone, .stress, .afterMeal, .driving, .coffee, .phone, .social
        ]
        let hours = [21, 13, 9, 21, 16, 22, 21, 8, 20, 21]
        let count = 38

        for index in 0..<count {
            // Weighted toward the early weeks, the way cravings actually thin out.
            let progress = Double(index) / Double(count)
            let daysAgo = max(1, Int(63 * pow(1 - progress, 0.6)))
            let moment = calendar.date(byAdding: .hour, value: hours[index % hours.count], to: day(daysAgo)) ?? day(daysAgo)

            context.insert(
                CravingEvent(
                    occurredAt: moment,
                    heldOutSeconds: 150 + (index * 37) % 210,
                    resisted: index % 13 != 6,
                    trigger: triggers[index % triggers.count]
                )
            )
        }
    }
}
#endif
