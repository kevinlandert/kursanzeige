import Foundation

/// The text read aloud for a chart, e.g. "Dow Jones, 1 Jahr, 25.178,
/// plus 12,8 Prozent". It uses the German number format: the German
/// voice reads "25.178" as a number, but not the Swiss "25'178". The
/// price has the decimals of the table, the change one decimal.
enum ChartSpeech {
    private static let germanLocale = Locale(identifier: "de_DE")

    /// Without `changePercent`, the text ends after the price.
    static func text(name: String, rangeName: String, price: Double, group: MarketGroup, changePercent: Double?) -> String {
        let parts = [name, rangeName, spokenPrice(price, group: group)]
        guard let changePercent else { return parts.joined(separator: ", ") }
        return (parts + [spokenChange(changePercent)]).joined(separator: ", ")
    }

    private static func spokenPrice(_ price: Double, group: MarketGroup) -> String {
        let maximumDecimals = PricePrecision.maximumFractionDigits(for: price, group: group)
        return price.formatted(.number.locale(germanLocale).precision(.fractionLength(0...maximumDecimals)).grouping(.automatic))
    }

    /// "plus" or "minus" before the value. A change that rounds to zero
    /// gets no sign, so the voice never says "minus 0,0". The check
    /// compares the formatted text: thus the sign and the number always
    /// use the same rounding rule.
    private static func spokenChange(_ percent: Double) -> String {
        let magnitude = oneDecimal(abs(percent))
        guard magnitude != oneDecimal(0) else { return "\(magnitude) Prozent" }
        return "\(percent < 0 ? "minus" : "plus") \(magnitude) Prozent"
    }

    private static func oneDecimal(_ value: Double) -> String {
        value.formatted(.number.locale(germanLocale).precision(.fractionLength(1)))
    }
}
