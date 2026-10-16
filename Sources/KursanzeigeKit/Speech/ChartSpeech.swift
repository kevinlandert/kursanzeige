/// The text read aloud for a chart, e.g. "Nestlé, 1 Jahr, 77,96 Franken,
/// plus 12,8 Prozent". `SpokenNumber` gives the number format.
enum ChartSpeech {
    /// Without `changePercent`, the text ends after the price. Without
    /// `currency`, the price has no currency word.
    static func text(name: String, rangeName: String, price: Double, group: MarketGroup, currency: String?, changePercent: Double?) -> String {
        let parts = [name, rangeName, SpokenNumber.price(price, group: group, currency: currency)]
        guard let changePercent else { return parts.joined(separator: ", ") }
        return (parts + [SpokenNumber.change(changePercent)]).joined(separator: ", ")
    }
}
