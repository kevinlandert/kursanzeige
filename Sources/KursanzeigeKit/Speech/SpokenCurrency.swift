/// The German word the voice says for a currency code.
enum SpokenCurrency {
    /// The currencies of the bundled constituents. The plural is the same
    /// as the singular for each of them.
    private static let names = [
        "CHF": "Franken",
        "USD": "Dollar",
        "EUR": "Euro",
        "GBP": "Pfund",
        "JPY": "Yen",
        "KRW": "Won",
        "HKD": "Hongkong-Dollar",
    ]

    /// An other code stays as it is: the voice then reads its letters.
    static func name(for code: String) -> String {
        names[code] ?? code
    }
}
