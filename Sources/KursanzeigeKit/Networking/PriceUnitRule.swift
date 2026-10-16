/// The unit of the prices of one symbol, from the Yahoo `instrumentType`
/// and `currency`. Yahoo gives a currency also for an index, but index
/// points are not money. An exchange rate tells both currencies in its
/// name. Thus the type decides, not the group of the instrument.
struct PriceUnitRule: Equatable {
    /// Yahoo gives some prices in a sub unit, e.g. London stocks in pence.
    /// The app shows them in the main unit.
    private static let mainUnitOfSubunit = ["GBp": "GBP", "GBX": "GBP", "ZAc": "ZAR", "ILA": "ILS"]
    private static let subunitsPerMainUnit = 100.0

    /// `nil` for an exchange rate, or for money without a Yahoo currency.
    let unit: PriceUnit?
    /// Divide each Yahoo price by this value to get a price in `unit`.
    let priceDivisor: Double

    init(instrumentType: String?, yahooCurrency: String?) {
        switch instrumentType {
        case "INDEX":
            self.init(unit: .points, priceDivisor: 1)
        case "CURRENCY":
            self.init(unit: nil, priceDivisor: 1)
        default:
            self.init(moneyIn: yahooCurrency)
        }
    }

    private init(moneyIn yahooCurrency: String?) {
        guard let yahooCurrency else {
            self.init(unit: nil, priceDivisor: 1)
            return
        }
        let mainUnit = Self.mainUnitOfSubunit[yahooCurrency]
        self.init(unit: .currency(mainUnit ?? yahooCurrency), priceDivisor: mainUnit == nil ? 1 : Self.subunitsPerMainUnit)
    }

    private init(unit: PriceUnit?, priceDivisor: Double) {
        self.unit = unit
        self.priceDivisor = priceDivisor
    }
}
