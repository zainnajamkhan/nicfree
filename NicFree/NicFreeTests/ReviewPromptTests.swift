import Foundation
import Testing

@testable import NicFree

/// When to ask for a review: after a milestone of a week or more, never after a slip.
@Suite("Review prompt")
struct ReviewPromptTests {

    @Test("The first look at Home only records where the person is")
    func reviewFirstLook() {
        let decision = ReviewPrompt.decide(finishedFreeDays: 40, last: nil, recentSlip: false)
        #expect(decision.remember == 30)
        #expect(!decision.ask)
    }

    @Test("A new milestone of a week or more asks once")
    func reviewAsksOnce() {
        let first = ReviewPrompt.decide(finishedFreeDays: 7, last: 3, recentSlip: false)
        #expect(first.ask && first.remember == 7)
        let again = ReviewPrompt.decide(finishedFreeDays: 8, last: first.remember, recentSlip: false)
        #expect(!again.ask)
    }

    @Test("Early milestones and fresh slips never ask")
    func reviewHoldsBack() {
        #expect(!ReviewPrompt.decide(finishedFreeDays: 3, last: 1, recentSlip: false).ask)
        let slip = ReviewPrompt.decide(finishedFreeDays: 14, last: 7, recentSlip: true)
        #expect(!slip.ask)
        #expect(slip.remember == 14)
    }
}
