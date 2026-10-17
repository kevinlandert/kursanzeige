import Foundation
import Testing
@testable import KursanzeigeKit

/// A table row reads the name, the price with its unit and the day
/// change, with German numbers.
@Suite("TableSpeech")
struct TableSpeechTests {
    private func createRow(_ name: String, group: MarketGroup, price: Double?, dayChangePercent: Double?, unit: PriceUnit? = nil) -> InstrumentRow {
        InstrumentRow(
            instrument: Instrument(symbol: name, name: name, group: group),
            price: price,
            asOf: nil,
            dayChangePercent: dayChangePercent,
            threeMonthChangePercent: nil,
            oneYearChangePercent: nil,
            unit: unit
        )
    }

    @Test("the text gives the name, the price and the day change")
    func textGivesNamePriceAndChange() {
        let row = createRow("DAX", group: .index, price: 24_010.2, dayChangePercent: -1.23)

        #expect(TableSpeech.text(row) == "DAX, 24.010, minus 1,2 Prozent.")
    }

    @Test("a currency keeps four decimals, as in the table")
    func currencyKeepsFourDecimals() {
        let row = createRow("EUR/CHF", group: .currencies, price: 0.93456, dayChangePercent: 0.1)

        #expect(TableSpeech.text(row) == "EUR/CHF, 0,9346, plus 0,1 Prozent.")
    }

    @Test("a stock price is followed by the name of its currency")
    func stockPriceIsFollowedByCurrencyName() {
        let row = createRow("Shell", group: .europe, price: 39.12, dayChangePercent: -0.3, unit: .currency("GBP"))

        #expect(TableSpeech.text(row) == "Shell, 39,12 Pfund, minus 0,3 Prozent.")
    }

    @Test("an index value is followed by the word Punkte")
    func indexValueIsFollowedByPoints() {
        let row = createRow("SMI", group: .index, price: 12_345.6, dayChangePercent: 0.54, unit: .points)

        #expect(TableSpeech.text(row) == "SMI, 12.346 Punkte, plus 0,5 Prozent.")
    }

    @Test("a row without a day change ends after the price")
    func rowWithoutDayChangeEndsAfterPrice() {
        let row = createRow("Nestlé", group: .switzerland, price: 77.96, dayChangePercent: nil)

        #expect(TableSpeech.text(row) == "Nestlé, 77,96.")
    }

    @Test("a row without a price says that it has no price")
    func rowWithoutPriceSaysNoPrice() {
        let row = createRow("Nestlé", group: .switzerland, price: nil, dayChangePercent: nil)

        #expect(TableSpeech.text(row) == "Nestlé, kein Kurs.")
    }
}
