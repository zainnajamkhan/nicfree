//
//  MilestoneScheduler.swift
//  NicFree
//

import Foundation
import UserNotifications

/// Milestones only. There is deliberately no "you have not logged today" reminder: there
/// is no check in to miss, and a guilt prompt would contradict the whole product.
///
/// Milestones count **finished free days**, not elapsed days, so a slip pushes the next one
/// further out and a day still in progress never counts. A local notification cannot re-evaluate itself on delivery, so the whole
/// schedule is torn down and rebuilt whenever the free day count changes. That is why
/// `reschedule` is cheap and safe to call often.
enum MilestoneScheduler {

    static let milestones = [1, 3, 7, 14, 30, 60, 90, 180, 365]

    /// Late morning: early enough to land in the day, late enough not to be an alarm.
    private static let hour = 10

    // MARK: - Authorization

    static func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    static func requestAuthorization() async -> Bool {
        let granted = (try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound])) ?? false
        // Schedule now, not at the next change in the count.
        if granted, let last = lastInputs {
            await reschedule(finishedFreeDays: last.finished, todayUsed: last.todayUsed)
        }
        return granted
    }

    // MARK: - Scheduling

    /// The inputs of the last schedule, so granting permission can schedule straight away
    /// instead of waiting for the free day count to change.
    private static var lastInputs: (finished: Int, todayUsed: Bool)?

    /// Days from today (at 10:00) on which each upcoming milestone should be announced.
    ///
    /// A milestone is earned when its last free day is over, so it's announced the morning
    /// after. With today free, the day that completes milestone M ends M - finished - 1 days
    /// from now. With a slip today, today doesn't count, so everything moves a day later.
    /// Milestones already reached are left out, and the offset is never zero, so nothing is
    /// scheduled in the past.
    static func announcementOffsets(
        finishedFreeDays finished: Int,
        todayUsed: Bool,
        milestones: [Int] = MilestoneScheduler.milestones
    ) -> [Int: Int] {
        var offsets: [Int: Int] = [:]
        for milestone in milestones where milestone > finished {
            offsets[milestone] = milestone - finished + (todayUsed ? 1 : 0)
        }
        return offsets
    }

    static func reschedule(finishedFreeDays: Int, todayUsed: Bool, calendar: Calendar = .current) async {
        lastInputs = (finishedFreeDays, todayUsed)

        let center = UNUserNotificationCenter.current()
        guard await authorizationStatus() == .authorized else { return }

        let offsets = announcementOffsets(finishedFreeDays: finishedFreeDays, todayUsed: todayUsed)

        // Only the ones still ahead. A milestone reached this morning may still be waiting
        // for its 10:00 slot, and clearing it here would lose it. Only our own requests:
        // the evening reminder lives in the same queue.
        center.removePendingNotificationRequests(withIdentifiers: offsets.keys.map { "milestone-\($0)" })

        let today = calendar.startOfDay(for: Date())

        for (milestone, daysAway) in offsets {
            guard let fireDay = calendar.date(byAdding: .day, value: daysAway, to: today) else { continue }

            var components = calendar.dateComponents([.year, .month, .day], from: fireDay)
            components.hour = hour

            let content = UNMutableNotificationContent()
            content.title = title(for: milestone)

            let request = UNNotificationRequest(
                identifier: "milestone-\(milestone)",
                content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            )

            try? await center.add(request)
        }
    }

    /// Warm and short. Also the headline of the milestone celebration on Home.
    static func title(for milestone: Int) -> String {
        switch milestone {
        case 1: String(localized: "One whole day free!")
        case 3: String(localized: "Three days free!")
        case 7: String(localized: "A whole week free!")
        case 14: String(localized: "Two weeks free!")
        case 30: String(localized: "A whole month free!")
        case 60: String(localized: "Two months free!")
        case 90: String(localized: "Three months free!")
        case 180: String(localized: "Six months free!")
        case 365: String(localized: "A whole year free!")
        default: String(localized: "\(milestone) days free!")
        }
    }
}
