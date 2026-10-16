/// The text read aloud for a chart, e.g. "Nestlé, 1 Jahr, 77,96 Franken,
/// plus 12,8 Prozent". `SpokenNumber` gives the number format.
enum ChartSpeech {
    /// Without `changePercent`, the text ends after the price. Without
    /// `unit`, the price has no unit word.
    static func text(name: String, rangeName: String, price: Double, group: MarketGroup, unit: PriceUnit?, changePercent: Double?) -> String {
        let parts = [name, rangeName, SpokenNumber.price(price, group: group, unit: unit)]
        guard let changePercent else { return parts.joined(separator: ", ") }
        return (parts + [SpokenNumber.change(changePercent)]).joined(separator: ", ")
    }
}
