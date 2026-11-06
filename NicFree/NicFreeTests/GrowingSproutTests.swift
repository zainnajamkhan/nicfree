import Testing

@testable import NicFree

/// The onboarding time lapse must only ever grow, start at a seedling and end golden.
@Suite("Growing sprout")
struct GrowingSproutTests {

    @Test("It starts as a seedling and ends golden")
    func endpoints() {
        #expect(GrowingSprout.days(at: 0) == 0)
        #expect(GrowingSprout.days(at: 1000) == 365)
    }

    @Test("It never shrinks along the way")
    func neverShrinks() {
        var last = -1.0
        for step in 0...1600 {
            let days = GrowingSprout.days(at: Double(step) / 100)
            #expect(days >= last)
            last = days
        }
    }

    @Test("Every stage is fully open at some moment")
    func everyStageReached() {
        var reached = Set<Int>()
        for step in 0...1600 {
            let days = GrowingSprout.days(at: Double(step) / 100)
            reached.insert(Sprout.stageIndex(freeDays: Int((days + 0.001).rounded(.down))))
        }
        #expect(reached.count == Sprout.stages.count)
    }
}
