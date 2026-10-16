import Foundation

/// The numbers of a text read aloud, in the German number format: the
/// German voice reads "25.178" as a number, but not the Swiss "25'178".
/// The price has the decimals of the table, the change one decimal.
enum SpokenNumber {
    private static let germanLocale = Locale(identifier: "de_DE")

    /// The unit word follows the number, e.g. "77,96 Franken" or
    /// "12.346 Punkte".
    static func price(_ price: Double, group: MarketGroup, unit: PriceUnit?) -> String {
        let maximumDecimals = PricePrecision.maximumFractionDigits(for: price, group: group)
        let number = price.formatted(.number.locale(germanLocale).precision(.fractionLength(0...maximumDecimals)).grouping(.automatic))
        switch unit {
        case .currency(let code): return "\(number) \(SpokenCurrency.name(for: code))"
        case .points: return "\(number) Punkte"
        case nil: return number
        }
    }

    /// "plus" or "minus" before the value. A change that rounds to zero
    /// gets no sign, so the voice never says "minus 0,0". The check
    /// compares the formatted text: thus the sign and the number always
    /// use the same rounding rule.
    static func change(_ percent: Double) -> String {
        let magnitude = oneDecimal(abs(percent))
        guard magnitude != oneDecimal(0) else { return "\(magnitude) Prozent" }
        return "\(percent < 0 ? "minus" : "plus") \(magnitude) Prozent"
    }

    private static func oneDecimal(_ value: Double) -> String {
        value.formatted(.number.locale(germanLocale).precision(.fractionLength(1)))
    }
}
