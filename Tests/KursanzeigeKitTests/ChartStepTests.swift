import Testing
@testable import KursanzeigeKit

@Suite("ChartStep")
struct ChartStepTests {
    @Test("a swipe to the left shows the next row, as when one turns a page")
    func swipeToTheLeftShowsNextRow() {
        #expect(ChartStep(swipeWidth: -120, height: 10) == .next)
    }

    @Test("a swipe to the right shows the previous row")
    func swipeToTheRightShowsPreviousRow() {
        #expect(ChartStep(swipeWidth: 120, height: -10) == .previous)
    }

    @Test("a short swipe does nothing, so a small slip of the finger has no effect")
    func shortSwipeDoesNothing() {
        #expect(ChartStep(swipeWidth: -40, height: 0) == nil)
        #expect(ChartStep(swipeWidth: 40, height: 0) == nil)
    }

    @Test("a swipe of exactly the minimum distance counts")
    func swipeOfMinimumDistanceCounts() {
        #expect(ChartStep(swipeWidth: -ChartStep.minimumSwipeDistance, height: 0) == .next)
        #expect(ChartStep(swipeWidth: ChartStep.minimumSwipeDistance, height: 0) == .previous)
    }

    @Test("a swipe that goes more up or down than sideways does nothing")
    func mostlyVerticalSwipeDoesNothing() {
        #expect(ChartStep(swipeWidth: -120, height: 200) == nil)
        #expect(ChartStep(swipeWidth: 120, height: -200) == nil)
    }

    @Test("a slanted swipe counts when it goes more sideways than up or down")
    func slantedSwipeCounts() {
        #expect(ChartStep(swipeWidth: -120, height: 90) == .next)
    }
}
