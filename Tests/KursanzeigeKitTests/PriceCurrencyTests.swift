import Testing
@testable import KursanzeigeKit

/// Yahoo gives a currency for each symbol, also for an index. Only the
/// price of a stock, a fund or a future is money.
@Suite("PriceCurrency")
struct PriceCurrencyTests {
    @Test("a stock, an ETF and a future show their currency")
    func stockFundAndFutureShowCurrency() {
        #expect(PriceCurrency(instrumentType: "EQUITY", yahooCurrency: "CHF").shownCurrency == "CHF")
        #expect(PriceCurrency(instrumentType: "ETF", yahooCurrency: "USD").shownCurrency == "USD")
        #expect(PriceCurrency(instrumentType: "FUTURE", yahooCurrency: "USD").shownCurrency == "USD")
    }

    @Test("an index has no currency, because its points are not money")
    func indexHasNoCurrency() {
        #expect(PriceCurrency(instrumentType: "INDEX", yahooCurrency: "KRW").shownCurrency == nil)
    }

    @Test("an exchange rate has no currency, because its name tells both currencies")
    func exchangeRateHasNoCurrency() {
        #expect(PriceCurrency(instrumentType: "CURRENCY", yahooCurrency: "CHF").shownCurrency == nil)
    }

    @Test("without an instrument type, the Yahoo currency shows")
    func missingTypeShowsCurrency() {
        #expect(PriceCurrency(instrumentType: nil, yahooCurrency: "EUR").shownCurrency == "EUR")
    }

    @Test("a London price in pence shows in pounds, divided by 100")
    func penceBecomePounds() {
        let currency = PriceCurrency(instrumentType: "EQUITY", yahooCurrency: "GBp")

        #expect(currency.shownCurrency == "GBP")
        #expect(currency.priceDivisor == 100)
    }

    @Test("an index in pence keeps its points, because only money changes to the main unit")
    func indexInPenceKeepsPoints() {
        #expect(PriceCurrency(instrumentType: "INDEX", yahooCurrency: "GBp").priceDivisor == 1)
    }

    @Test("a price in a main unit keeps its value")
    func mainUnitKeepsValue() {
        #expect(PriceCurrency(instrumentType: "EQUITY", yahooCurrency: "CHF").priceDivisor == 1)
    }
}
