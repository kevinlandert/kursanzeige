/// The texts of a list for the voice and for the status line.
enum ListTexts {
    static let listStart = "Anfang der Liste."
    static let listEnd = "Ende der Liste."
    /// A group can be empty when the person removed all its instruments.
    static let emptyList = "Keine Kurse."
    static let emptyListStatus = "Keine Kurse"

    /// „Nestlé ausgewählt“, or „Liest vor · Nestlé“. The rows have no
    /// numbers: the name tells the row.
    /// - Parameter title: the name of the cursor row. Nil for a list without rows.
    static func status(title: String?, isReading: Bool) -> String {
        guard let title else { return emptyListStatus }
        return isReading ? "Liest vor · \(title)" : "\(title) ausgewählt"
    }
}
