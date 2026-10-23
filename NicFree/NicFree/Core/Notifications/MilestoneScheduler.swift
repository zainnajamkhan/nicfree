//
//  MilestoneScheduler.swift
//  NicFree
//

import Foundation
import UserNotifications

/// Milestones only. There is deliberately no "you have not logged today" reminder: there
/// is no check in to miss, and a guilt prompt would contradict the whole product.
///
/// Milestones count **free days**, not elapsed days, so a slip pushes the next one
/// further out. A local notification cannot re-evaluate itself on delivery, so the whole
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
        (try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound])) ?? false
    }

    // MARK: - Scheduling

    static func reschedule(freeDays: Int, calendar: Calendar = .current) async {
        let center = UNUserNotificationCenter.current()
        guard await authorizationStatus() == .authorized else { return }

        // Only our own requests: the evening reminder lives in the same queue.
        center.removePendingNotificationRequests(withIdentifiers: milestones.map { "milestone-\($0)" })

        let today = calendar.startOfDay(for: Date())

        for milestone in milestones where milestone > freeDays {
            let daysAway = milestone - freeDays
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
