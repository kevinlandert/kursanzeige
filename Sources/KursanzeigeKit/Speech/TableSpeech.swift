/// The text read aloud for a table row, e.g. „Nvidia, 217,23 Dollar, Tag
/// minus 1,8 Prozent.“ The name is always read. The settings choose the
/// other columns. Each change starts with its column name, so the person
/// knows the column. The voice tells the unit of the price, because a
/// number alone is not clear.
enum TableSpeech {
    /// The full stop gives the voice a pause before the next row.
    static func text(_ row: InstrumentRow, settings: TableSpeechSettings) -> String {
        "\(([row.instrument.name] + columnTexts(row, settings: settings)).joined(separator: ", "))."
    }

    /// A missing change is left out. A missing price says „kein Kurs“, so
    /// the person knows that the row has no data.
    private static func columnTexts(_ row: InstrumentRow, settings: TableSpeechSettings) -> [String] {
        var texts: [String] = []
        if settings.columns.contains(.price) {
            texts.append(row.price.map { SpokenNumber.price($0, group: row.instrument.group, unit: row.unit) } ?? "kein Kurs")
        }
        let changes: [(SpokenColumns, String, Double?)] = [
            (.day, "Tag", row.dayChangePercent),
            (.shortRange, settings.rangeMode.spokenName, shortRangeValue(row, settings.rangeMode)),
            (.longRange, settings.oneYearMode.spokenName, longRangeValue(row, settings.oneYearMode)),
        ]
        for (column, name, value) in changes where settings.columns.contains(column) {
            guard let value else { continue }
            texts.append("\(name) \(SpokenNumber.change(value))")
        }
        return texts
    }

    private static func shortRangeValue(_ row: InstrumentRow, _ mode: RangeMode) -> Double? {
        mode == .oneMonth ? row.oneMonthChangePercent : row.threeMonthChangePercent
    }

    private static func longRangeValue(_ row: InstrumentRow, _ mode: OneYearMode) -> Double? {
        mode == .trailing ? row.oneYearChangePercent : row.yearToDateChangePercent
    }
}
