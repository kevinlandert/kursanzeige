import Testing
@testable import KursanzeigeKit

/// The chart keeps a width to height ratio from 1.5 to 2, so a move looks
/// about as steep in portrait as in landscape.
@Suite("ChartShape")
struct ChartShapeTests {
    @Test("a tall space, as in portrait, gives a lower chart with the ratio 1.5")
    func tallSpaceGivesLowerChart() {
        let size = ChartShape.fit(width: 1000, height: 800)

        #expect(size.width == 1000)
        #expect(abs(size.height - 1000 / 1.5) < 0.001)
    }

    @Test("a wide space, as in landscape, gives a narrower chart with the ratio 2")
    func wideSpaceGivesNarrowerChart() {
        let size = ChartShape.fit(width: 1350, height: 470)

        #expect(size == ChartSize(width: 940, height: 470))
    }

    @Test("a space with a ratio from 1.5 to 2 is used in full", arguments: [(900.0, 600.0), (1000.0, 600.0), (1000.0, 500.0)])
    func spaceInRangeIsUsedInFull(width: Double, height: Double) {
        #expect(ChartShape.fit(width: width, height: height) == ChartSize(width: width, height: height))
    }

    @Test("a space without width or height gives no chart")
    func emptySpaceGivesNoChart() {
        #expect(ChartShape.fit(width: 0, height: 500) == ChartSize(width: 0, height: 0))
        #expect(ChartShape.fit(width: 800, height: 0) == ChartSize(width: 0, height: 0))
    }
}
