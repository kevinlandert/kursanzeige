import Testing
@testable import KursanzeigeKit

@Suite("ChartSpeech")
struct ChartSpeechTests {
    @Test("the text gives name, range, price and change, with German numbers")
    func textGivesNameRangePriceAndChange() {
        let text = ChartSpeech.text(name: "Dow Jones", rangeName: "1 Jahr", price: 25_178.4, group: .index, changePercent: 12.83)

        #expect(text == "Dow Jones, 1 Jahr, 25.178, plus 12,8 Prozent")
    }

    @Test("a fall is spoken as minus")
    func fallIsSpokenAsMinus() {
        let text = ChartSpeech.text(name: "Nestlé", rangeName: "3 Monate", price: 77.96, group: .switzerland, changePercent: -1.84)

        #expect(text == "Nestlé, 3 Monate, 77,96, minus 1,8 Prozent")
    }

    @Test("a change that rounds to zero has no sign")
    func changeRoundingToZeroHasNoSign() {
        let text = ChartSpeech.text(name: "Nestlé", rangeName: "1 Monat", price: 77.96, group: .switzerland, changePercent: -0.04)

        #expect(text == "Nestlé, 1 Monat, 77,96, 0,0 Prozent")
    }

    @Test("a currency keeps four decimals, as in the table")
    func currencyKeepsFourDecimals() {
        let text = ChartSpeech.text(name: "EUR/CHF", rangeName: "1 Jahr", price: 0.93456, group: .currencies, changePercent: 1.0)

        #expect(text == "EUR/CHF, 1 Jahr, 0,9346, plus 1,0 Prozent")
    }

    @Test("without a change, the text ends after the price")
    func textWithoutChangeEndsAfterPrice() {
        let text = ChartSpeech.text(name: "Nestlé", rangeName: "1 Jahr", price: 77.96, group: .switzerland, changePercent: nil)

        #expect(text == "Nestlé, 1 Jahr, 77,96")
    }
}

@Suite("PricePrecision")
struct PricePrecisionTests {
    @Test("a stock price has up to two decimals")
    func stockPriceHasTwoDecimals() {
        #expect(PricePrecision.maximumFractionDigits(for: 77.96, group: .switzerland) == 2)
    }

    @Test("a currency rate has up to four decimals")
    func currencyRateHasFourDecimals() {
        #expect(PricePrecision.maximumFractionDigits(for: 0.93, group: .currencies) == 4)
    }

    @Test("a value of 1000 or more has no decimals, in every group")
    func largeValueHasNoDecimals() {
        #expect(PricePrecision.maximumFractionDigits(for: 1_000, group: .index) == 0)
        #expect(PricePrecision.maximumFractionDigits(for: -1_500, group: .currencies) == 0)
    }
}
