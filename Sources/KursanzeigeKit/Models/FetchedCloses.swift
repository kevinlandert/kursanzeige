/// The daily closes of one symbol from one request, with the unit of the
/// prices.
struct FetchedCloses: Equatable, Sendable {
    let closes: [ClosePoint]
    /// See `PriceUnitRule`.
    let unit: PriceUnit?

    init(closes: [ClosePoint], unit: PriceUnit? = nil) {
        self.closes = closes
        self.unit = unit
    }
}
