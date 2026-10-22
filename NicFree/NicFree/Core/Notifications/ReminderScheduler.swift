//
//  ReminderScheduler.swift
//  NicFree
//

import Foundation
import UserNotifications

/// The opt-in evening reminder. Off by default, one a day, and never phrased as a missed
/// obligation: a free day needs nothing, so the note says so.
enum ReminderScheduler {

    static let identifier = "evening-reminder"
    static let defaultMinute = 20 * 60

    static func update(minuteOfDay: Int?) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        guard let minuteOfDay, await MilestoneScheduler.authorizationStatus() == .authorized else { return }

        var time = DateComponents()
        time.hour = minuteOfDay / 60
        time.minute = minuteOfDay % 60

        let content = UNMutableNotificationContent()
        content.title = String(localized: "How did today go?")
        content.body = String(localized: "Nothing to do if it was a free day.")

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
        )
        try? await center.add(request)
    }
}
