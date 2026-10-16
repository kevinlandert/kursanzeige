/// The German word the voice says for a currency code.
enum SpokenCurrency {
    /// The currencies of the bundled constituents, and of other large
    /// markets for a ticker that the person adds. Each word is plural,
    /// because a price is almost never exactly 1.
    private static let names = [
        "CHF": "Franken",
        "USD": "Dollar",
        "EUR": "Euro",
        "GBP": "Pfund",
        "JPY": "Yen",
        "KRW": "Won",
        "HKD": "Hongkong-Dollar",
        "CNY": "Yuan",
        "TWD": "Taiwan-Dollar",
        "SGD": "Singapur-Dollar",
        "INR": "Rupien",
        "AUD": "Australische Dollar",
        "NZD": "Neuseeland-Dollar",
        "CAD": "Kanadische Dollar",
        "MXN": "Mexikanische Pesos",
        "BRL": "Real",
        "SEK": "Schwedische Kronen",
        "NOK": "Norwegische Kronen",
        "DKK": "Dänische Kronen",
        "PLN": "Zloty",
        "CZK": "Tschechische Kronen",
        "HUF": "Forint",
        "TRY": "Türkische Lira",
        "ZAR": "Rand",
        "ILS": "Schekel",
    ]

    /// An other code stays as it is: the voice then reads its letters.
    static func name(for code: String) -> String {
        names[code] ?? code
    }
}
