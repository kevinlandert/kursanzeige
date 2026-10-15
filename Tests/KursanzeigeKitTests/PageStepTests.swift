import Testing
@testable import KursanzeigeKit

@Suite("PageStep")
struct PageStepTests {
    @Test("a swipe to the left shows the next page, as when one turns a page")
    func swipeToTheLeftShowsNextPage() {
        #expect(PageStep(swipeWidth: -120, height: 10) == .next)
    }

    @Test("a swipe to the right shows the previous page")
    func swipeToTheRightShowsPreviousPage() {
        #expect(PageStep(swipeWidth: 120, height: -10) == .previous)
    }

    @Test("a short swipe does nothing, so a small slip of the finger has no effect")
    func shortSwipeDoesNothing() {
        #expect(PageStep(swipeWidth: -40, height: 0) == nil)
        #expect(PageStep(swipeWidth: 40, height: 0) == nil)
    }

    @Test("a swipe of exactly the minimum distance counts")
    func swipeOfMinimumDistanceCounts() {
        #expect(PageStep(swipeWidth: -PageStep.minimumSwipeDistance, height: 0) == .next)
        #expect(PageStep(swipeWidth: PageStep.minimumSwipeDistance, height: 0) == .previous)
    }

    @Test("a swipe that goes more up or down than sideways does nothing")
    func mostlyVerticalSwipeDoesNothing() {
        #expect(PageStep(swipeWidth: -120, height: 200) == nil)
        #expect(PageStep(swipeWidth: 120, height: -200) == nil)
    }

    @Test("a slanted swipe counts when it goes more sideways than up or down")
    func slantedSwipeCounts() {
        #expect(PageStep(swipeWidth: -120, height: 90) == .next)
    }
}
