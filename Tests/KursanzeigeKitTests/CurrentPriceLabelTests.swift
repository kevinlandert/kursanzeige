import Testing
@testable import KursanzeigeKit

/// The label of the current price on the right axis always shows. Near
/// the high or the low label, it moves away, so the texts do not overlap.
/// The examples use a low of 100, a high of 200 and a gap of 10 %.
@Suite("CurrentPriceLabel")
struct CurrentPriceLabelTests {
    private static let low = 100.0
    private static let high = 200.0
    private static let gapShare = 0.1

    private func labelPosition(current: Double) -> Double? {
        CurrentPriceLabel.axisValue(current: current, low: Self.low, high: Self.high, minimumGapShare: Self.gapShare)
    }

    @Test("a price far from the high and the low has its label at the price")
    func priceInTheMiddleKeepsItsPlace() {
        #expect(labelPosition(current: 150) == 150)
    }

    @Test("a price near the high has its label moved down to the minimum gap below the high")
    func priceNearHighMovesDown() {
        #expect(labelPosition(current: 195) == 190)
    }

    @Test("a price equal to the high has its label moved down to the minimum gap")
    func priceAtHighMovesDown() {
        #expect(labelPosition(current: 200) == 190)
    }

    @Test("a price near the low has its label moved up to the minimum gap above the low")
    func priceNearLowMovesUp() {
        #expect(labelPosition(current: 103) == 110)
    }

    @Test("a price exactly at the minimum gap keeps its place")
    func priceAtMinimumGapKeepsItsPlace() {
        #expect(labelPosition(current: 190) == 190)
        #expect(labelPosition(current: 110) == 110)
    }

    @Test("a gap share above one half puts the label in the middle, the only place far from both")
    func tooLargeGapPutsLabelInTheMiddle() {
        #expect(CurrentPriceLabel.axisValue(current: 195, low: Self.low, high: Self.high, minimumGapShare: 0.7) == 150)
    }

    @Test("a flat line has no current price label: the high and low label show the same price")
    func flatLineHasNoLabel() {
        #expect(CurrentPriceLabel.axisValue(current: 150, low: 150, high: 150, minimumGapShare: Self.gapShare) == nil)
    }
}
