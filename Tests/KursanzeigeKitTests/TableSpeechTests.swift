import Foundation
import Testing
@testable import KursanzeigeKit

/// A table row always reads the name. The settings choose the other
/// columns. Each change says its column name first, so the person knows
/// which column it is.
@Suite("TableSpeech")
struct TableSpeechTests {
    private func createRow(
        _ name: String, group: MarketGroup, price: Double?, day: Double? = nil, unit: PriceUnit? = nil,
        oneMonth: Double? = nil, threeMonths: Double? = nil, oneYear: Double? = nil, yearToDate: Double? = nil
    ) -> InstrumentRow {
        InstrumentRow(
            instrument: Instrument(symbol: name, name: name, group: group),
            price: price,
            asOf: nil,
            dayChangePercent: day,
            threeMonthChangePercent: threeMonths,
            oneYearChangePercent: oneYear,
            yearToDateChangePercent: yearToDate,
            oneMonthChangePercent: oneMonth,
            unit: unit
        )
    }

    private func createSettings(_ columns: SpokenColumns, rangeMode: RangeMode = .threeMonth, oneYearMode: OneYearMode = .trailing) -> TableSpeechSettings {
        TableSpeechSettings(columns: columns, rangeMode: rangeMode, oneYearMode: oneYearMode)
    }

    @Test("the standard settings read the name, the price and the day change")
    func standardReadsNamePriceAndDay() {
        let row = createRow("Nestlé", group: .switzerland, price: 77.96, day: 0.54, unit: .currency("CHF"))

        #expect(TableSpeech.text(row, settings: .standard) == "Nestlé, 77,96 Franken, Tag plus 0,5 Prozent.")
    }

    @Test("all columns with 1 Monat and YTD say the name of each column")
    func allColumnsSayTheirNames() {
        let row = createRow("Nvidia", group: .usa, price: 217.23, day: -1.8, unit: .currency("USD"), oneMonth: 2.2, yearToDate: 5)
        let settings = createSettings([.price, .day, .shortRange, .longRange], rangeMode: .oneMonth, oneYearMode: .yearToDate)

        #expect(TableSpeech.text(row, settings: settings) == "Nvidia, 217,23 Dollar, Tag minus 1,8 Prozent, ein Monat plus 2,2 Prozent, seit Jahresbeginn plus 5,0 Prozent.")
    }

    @Test("3 Monate and 1 Jahr read the values of those columns")
    func threeMonthsAndOneYearReadTheirValues() {
        let row = createRow("SMI", group: .index, price: 12_345.6, threeMonths: -3.3, oneYear: 12.8)
        let settings = createSettings([.shortRange, .longRange])

        #expect(TableSpeech.text(row, settings: settings) == "SMI, 3 Monate minus 3,3 Prozent, 1 Jahr plus 12,8 Prozent.")
    }

    @Test("without other columns the row reads only the name")
    func noColumnsReadsOnlyName() {
        let row = createRow("Nestlé", group: .switzerland, price: 77.96, day: 0.5)

        #expect(TableSpeech.text(row, settings: createSettings([])) == "Nestlé.")
    }

    @Test("a missing change is left out")
    func missingChangeIsLeftOut() {
        let row = createRow("Nestlé", group: .switzerland, price: 77.96, unit: .currency("CHF"))

        #expect(TableSpeech.text(row, settings: .standard) == "Nestlé, 77,96 Franken.")
    }

    @Test("a row without a price says that it has no price")
    func rowWithoutPriceSaysNoPrice() {
        let row = createRow("Nestlé", group: .switzerland, price: nil)

        #expect(TableSpeech.text(row, settings: .standard) == "Nestlé, kein Kurs.")
    }

    @Test("a currency keeps four decimals, as in the table")
    func currencyKeepsFourDecimals() {
        let row = createRow("EUR/CHF", group: .currencies, price: 0.93456, day: 0.1)

        #expect(TableSpeech.text(row, settings: .standard) == "EUR/CHF, 0,9346, Tag plus 0,1 Prozent.")
    }

    @Test("an index value is followed by the word Punkte")
    func indexValueIsFollowedByPoints() {
        let row = createRow("SMI", group: .index, price: 12_345.6, day: 0.54, unit: .points)

        #expect(TableSpeech.text(row, settings: .standard) == "SMI, 12.346 Punkte, Tag plus 0,5 Prozent.")
    }
}
