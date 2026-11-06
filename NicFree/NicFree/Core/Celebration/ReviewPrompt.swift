//
//  ReviewPrompt.swift
//  NicFree
//

import Foundation

/// When to ask for an App Store review: once, right after a real milestone, never after a
/// slip. Apple also caps how often the system shows the prompt, so asking is cheap.
enum ReviewPrompt {

    /// A week is the first milestone worth asking about.
    static let smallestMilestone = 7

    /// The milestone to remember, and whether to ask now.
    ///
    /// `last` is nil on the very first look, which only sets the starting point.
    static func decide(
        finishedFreeDays: Int,
        last: Int?,
        recentSlip: Bool,
        milestones: [Int] = MilestoneScheduler.milestones
    ) -> (remember: Int, ask: Bool) {
        let reached = milestones.filter { $0 <= finishedFreeDays }.max() ?? 0
        guard let last else { return (reached, false) }
        guard reached > last else { return (last, false) }
        return (reached, reached >= smallestMilestone && !recentSlip)
    }
}
