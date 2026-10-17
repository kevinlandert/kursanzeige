/// The text read aloud for a table row, e.g. „Nestlé, 77,96 Franken,
/// plus 0,5 Prozent.“ It gives the name, the price with its unit and the
/// day change. The table shows no unit,
/// but the voice tells it, because a number alone is not clear.
/// `SpokenNumber` gives the number format.
enum TableSpeech {
    /// The full stop gives the voice a pause before the next row.
    static func text(_ row: InstrumentRow) -> String {
        "\(rowText(row))."
    }

    private static func rowText(_ row: InstrumentRow) -> String {
        guard let price = row.price else { return "\(row.instrument.name), kein Kurs" }
        let parts = [row.instrument.name, SpokenNumber.price(price, group: row.instrument.group, unit: row.unit)]
        guard let dayChangePercent = row.dayChangePercent else { return parts.joined(separator: ", ") }
        return (parts + [SpokenNumber.change(dayChangePercent)]).joined(separator: ", ")
    }
}
