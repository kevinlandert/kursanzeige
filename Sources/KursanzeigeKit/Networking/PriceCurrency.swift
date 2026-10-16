/// The currency the app shows for the prices of one symbol, from the
/// Yahoo `instrumentType` and `currency`. Yahoo gives a currency also for
/// an index, but index points are not money. An exchange rate tells both
/// currencies in its name.
struct PriceCurrency: Equatable {
    /// Yahoo gives some prices in a sub unit, e.g. London stocks in pence.
    /// The app shows them in the main unit.
    private static let mainUnitOfSubunit = ["GBp": "GBP", "GBX": "GBP", "ZAc": "ZAR", "ILA": "ILS"]
    private static let subunitsPerMainUnit = 100.0
    private static let typesWithoutCurrency: Set = ["INDEX", "CURRENCY"]

    /// `nil` for an index or an exchange rate.
    let shownCurrency: String?
    /// Divide each Yahoo price by this value to get a price in `shownCurrency`.
    let priceDivisor: Double

    init(instrumentType: String?, yahooCurrency: String?) {
        let isMoney = !Self.typesWithoutCurrency.contains(instrumentType ?? "")
        guard isMoney, let yahooCurrency else {
            self.shownCurrency = nil
            self.priceDivisor = 1
            return
        }
        let mainUnit = Self.mainUnitOfSubunit[yahooCurrency]
        self.shownCurrency = mainUnit ?? yahooCurrency
        self.priceDivisor = mainUnit == nil ? 1 : Self.subunitsPerMainUnit
    }
}
