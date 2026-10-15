import Testing
@testable import KursanzeigeKit

/// A swipe on the main page goes to the neighbor group, in the order of
/// the group buttons.
@Suite("MarketGroup")
struct MarketGroupTests {
    @Test("the next group of Index is Währungen")
    func nextGroupOfIndexIsCurrencies() {
        #expect(MarketGroup.index.neighbor(.next) == .currencies)
    }

    @Test("the previous group of Währungen is Index")
    func previousGroupOfCurrenciesIsIndex() {
        #expect(MarketGroup.currencies.neighbor(.previous) == .index)
    }

    @Test("Index, the first group, has no previous group")
    func firstGroupHasNoPreviousGroup() {
        #expect(MarketGroup.index.neighbor(.previous) == nil)
    }

    @Test("Welt, the last group, has no next group")
    func lastGroupHasNoNextGroup() {
        #expect(MarketGroup.world.neighbor(.next) == nil)
    }

    @Test("steps to the next group go through all groups in the order of the buttons")
    func nextStepsGoThroughAllGroupsInButtonOrder() {
        var visited = [MarketGroup.index]
        while let next = visited.last?.neighbor(.next) {
            visited.append(next)
        }
        #expect(visited == [.index, .currencies, .switzerland, .usa, .europe, .world])
    }
}
