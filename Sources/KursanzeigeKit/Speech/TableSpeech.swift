/// The text read aloud for the table on the main page, e.g. "Schweiz.
/// Nestlé, 77,96 Franken, plus 0,5 Prozent. …". It gives the name, the
/// price with its currency and the day change. The table shows no
/// currency, but the voice tells it, because a number alone is not
/// clear. A full stop after each row gives the voice a pause.
/// `SpokenNumber` gives the number format.
enum TableSpeech {
    /// The group name comes first: after a swipe, the person hears which
    /// group the table shows.
    static func text(group: MarketGroup, rows: [InstrumentRow]) -> String {
        ([group.displayName] + rows.map(rowText)).map { "\($0)." }.joined(separator: " ")
    }

    private static func rowText(_ row: InstrumentRow) -> String {
        guard let price = row.price else { return "\(row.instrument.name), kein Kurs" }
        let parts = [row.instrument.name, SpokenNumber.price(price, group: row.instrument.group, currency: row.currency)]
        guard let dayChangePercent = row.dayChangePercent else { return parts.joined(separator: ", ") }
        return (parts + [SpokenNumber.change(dayChangePercent)]).joined(separator: ", ")
    }
}
