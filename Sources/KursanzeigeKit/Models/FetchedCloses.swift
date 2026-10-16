/// The daily closes of one symbol from one request, with the currency of
/// the prices.
struct FetchedCloses: Equatable, Sendable {
    let closes: [ClosePoint]
    /// An ISO code, e.g. "CHF". `nil` when the price is not money: an
    /// index or an exchange rate. See `PriceCurrency`.
    let currency: String?

    init(closes: [ClosePoint], currency: String? = nil) {
        self.closes = closes
        self.currency = currency
    }
}
