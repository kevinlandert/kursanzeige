/// The texts of a list for the voice and for the status line.
enum ListTexts {
    static let listStart = "Anfang der Liste."
    static let listEnd = "Ende der Liste."
    /// A group can be empty when the person removed all its instruments.
    static let emptyList = "Keine Kurse."
    static let emptyListStatus = "Keine Kurse"

    /// The status line shows the numbers as digits. Only the voice says
    /// them as words.
    static func status(cursorIndex: Int, rowCount: Int, isReading: Bool) -> String {
        guard rowCount > 0 else { return emptyListStatus }
        let position = "Nummer \(cursorIndex + 1) von \(rowCount)"
        return isReading ? "Liest vor · \(position)" : "\(position) ausgewählt"
    }

    /// „Nummer drei.“ before the text of a row. The voice reads „Nummer 3.“
    /// as „Nummer dritte“, so the number is a word.
    static func numbered(_ text: String, number: Int) -> String {
        "Nummer \(SpokenNumber.word(number)). \(text)"
    }
}
