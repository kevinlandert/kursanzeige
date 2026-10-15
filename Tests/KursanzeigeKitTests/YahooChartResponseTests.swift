import Testing
import Foundation
@testable import KursanzeigeKit

struct YahooChartResponseTests {

    private func loadFixture(_ name: String) throws -> YahooChartResponse {
        let url = try #require(Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures"))
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(YahooChartResponse.self, from: data)
    }

    @Test func decodesEquityFixtureWithNoGaps() throws {
        let response = try loadFixture("NESN.SW")
        #expect(response.chart.result?.first?.meta.symbol == "NESN.SW")
        let points = try response.closePoints()
        // A year of Swiss trading days, no nulls in this fixture.
        #expect(points.count > 200)
        // Last close matches the live regularMarketPrice observed when the fixture was captured.
        #expect(points.last?.close == 77.95999908447266)
    }

    @Test func decodesCurrencyFixtureAndDropsNullCloses() throws {
        let response = try loadFixture("EURCHF=X")
        let points = try response.closePoints()
        // Fixture has 263 timestamps with 3 null closes -> 260 usable points.
        #expect(points.count == 260)
        #expect(points.allSatisfy { $0.close > 0 })
    }

    @Test func closePointsAreOrderedByAscendingTimestamp() throws {
        let response = try loadFixture("NESN.SW")
        let points = try response.closePoints()
        let dates = points.map(\.date)
        #expect(dates == dates.sorted())
    }

    @Test func throwsMissingResultForEmptyChart() {
        let json = #"{"chart":{"result":null,"error":null}}"#.data(using: .utf8)!
        let response = try? JSONDecoder().decode(YahooChartResponse.self, from: json)
        #expect(throws: YahooChartResponse.ConversionError.self) {
            _ = try response?.closePoints()
        }
    }

    @Test func throwsApiErrorWhenChartReportsOne() {
        let json = #"{"chart":{"result":null,"error":{"code":"Not Found","description":"No data found, symbol may be delisted"}}}"#.data(using: .utf8)!
        let response = try! JSONDecoder().decode(YahooChartResponse.self, from: json)
        #expect(throws: YahooChartResponse.ConversionError.self) {
            _ = try response.closePoints()
        }
    }
}
