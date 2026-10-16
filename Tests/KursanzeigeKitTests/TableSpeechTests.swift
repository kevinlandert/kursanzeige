import Foundation
import Testing
@testable import KursanzeigeKit

/// "Vorlesen" on the main page reads the group name, then name, price
/// and day change of each row, in the order of the table.
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

    @Test("the text gives the group, then name, price and day change of each row, with German numbers")
    func textGivesGroupThenEachRow() {
        let rows = [
            createRow("SMI", group: .index, price: 12_345.6, dayChangePercent: 0.54),
            createRow("DAX", group: .index, price: 24_010.2, dayChangePercent: -1.23),
        ]

        let text = TableSpeech.text(group: .index, rows: rows)

        #expect(text == "Index. SMI, 12.346, plus 0,5 Prozent. DAX, 24.010, minus 1,2 Prozent.")
    }

    @Test("a currency keeps four decimals, as in the table")
    func currencyKeepsFourDecimals() {
        let rows = [createRow("EUR/CHF", group: .currencies, price: 0.93456, dayChangePercent: 0.1)]

        let text = TableSpeech.text(group: .currencies, rows: rows)

        #expect(text == "Währungen. EUR/CHF, 0,9346, plus 0,1 Prozent.")
    }

    @Test("a stock price is followed by the name of its currency")
    func stockPriceIsFollowedByCurrencyName() {
        let rows = [createRow("Shell", group: .europe, price: 39.12, dayChangePercent: -0.3, unit: .currency("GBP"))]

        let text = TableSpeech.text(group: .europe, rows: rows)

        #expect(text == "Europa. Shell, 39,12 Pfund, minus 0,3 Prozent.")
    }

    @Test("an index value is followed by the word Punkte")
    func indexValueIsFollowedByPoints() {
        let rows = [createRow("SMI", group: .index, price: 12_345.6, dayChangePercent: 0.54, unit: .points)]

        let text = TableSpeech.text(group: .index, rows: rows)

        #expect(text == "Index. SMI, 12.346 Punkte, plus 0,5 Prozent.")
    }

    @Test("a row without a day change ends after the price")
    func rowWithoutDayChangeEndsAfterPrice() {
        let rows = [createRow("Nestlé", group: .switzerland, price: 77.96, dayChangePercent: nil)]

        let text = TableSpeech.text(group: .switzerland, rows: rows)

        #expect(text == "Schweiz. Nestlé, 77,96.")
    }

    @Test("a row without a price says that it has no price")
    func rowWithoutPriceSaysNoPrice() {
        let rows = [createRow("Nestlé", group: .switzerland, price: nil, dayChangePercent: nil)]

        let text = TableSpeech.text(group: .switzerland, rows: rows)

        #expect(text == "Schweiz. Nestlé, kein Kurs.")
    }

    @Test("a group without rows gives only the group name")
    func groupWithoutRowsGivesOnlyGroupName() {
        #expect(TableSpeech.text(group: .usa, rows: []) == "USA.")
    }
}
