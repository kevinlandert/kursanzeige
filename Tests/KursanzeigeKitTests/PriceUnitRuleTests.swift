import Foundation
import Testing
@testable import KursanzeigeKit

/// Yahoo gives a currency for each symbol, also for an index. Only the
/// price of a stock, a fund or a future is money. An index has points.
@Suite("PriceUnitRule")
struct PriceUnitRuleTests {
    @Test("a stock, an ETF and a future have their currency as unit")
    func stockFundAndFutureHaveCurrency() {
        #expect(PriceUnitRule(instrumentType: "EQUITY", yahooCurrency: "CHF").unit == .currency("CHF"))
        #expect(PriceUnitRule(instrumentType: "ETF", yahooCurrency: "USD").unit == .currency("USD"))
        #expect(PriceUnitRule(instrumentType: "FUTURE", yahooCurrency: "USD").unit == .currency("USD"))
    }

    @Test("an index has points as unit, because its value is not money")
    func indexHasPoints() {
        #expect(PriceUnitRule(instrumentType: "INDEX", yahooCurrency: "KRW").unit == .points)
    }

    @Test("an exchange rate has no unit, because its name tells both currencies")
    func exchangeRateHasNoUnit() {
        #expect(PriceUnitRule(instrumentType: "CURRENCY", yahooCurrency: "CHF").unit == nil)
    }

    @Test("without an instrument type, the Yahoo currency is the unit")
    func missingTypeGivesCurrency() {
        #expect(PriceUnitRule(instrumentType: nil, yahooCurrency: "EUR").unit == .currency("EUR"))
    }

    @Test("a London price in pence shows in pounds, divided by 100")
    func penceBecomePounds() {
        let rule = PriceUnitRule(instrumentType: "EQUITY", yahooCurrency: "GBp")

        #expect(rule.unit == .currency("GBP"))
        #expect(rule.priceDivisor == 100)
    }

    @Test("an index in pence keeps its points, because only money changes to the main unit")
    func indexInPenceKeepsPoints() {
        let rule = PriceUnitRule(instrumentType: "INDEX", yahooCurrency: "GBp")

        #expect(rule.unit == .points)
        #expect(rule.priceDivisor == 1)
    }

    @Test("a price in a main unit keeps its value")
    func mainUnitKeepsValue() {
        #expect(PriceUnitRule(instrumentType: "EQUITY", yahooCurrency: "CHF").priceDivisor == 1)
    }
}

/// The unit goes into the stored files as one short text.
@Suite("PriceUnit")
struct PriceUnitTests {
    @Test("a currency and points keep their value in a stored file", arguments: [PriceUnit.currency("CHF"), .points])
    func unitKeepsValueInFile(unit: PriceUnit) throws {
        let decoded = try JSONDecoder().decode(PriceUnit.self, from: JSONEncoder().encode(unit))

        #expect(decoded == unit)
    }

    @Test("only a currency has a currency code")
    func onlyCurrencyHasCode() {
        #expect(PriceUnit.currency("CHF").currencyCode == "CHF")
        #expect(PriceUnit.points.currencyCode == nil)
    }
}
