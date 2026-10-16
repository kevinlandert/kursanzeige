/// The unit of a price: a currency for a stock, a fund or a future, or
/// points for an index. An exchange rate has no unit: its name tells both
/// currencies. See `PriceUnitRule`.
public enum PriceUnit: Equatable, Sendable {
    /// An ISO code, e.g. "CHF".
    case currency(String)
    case points

    /// The ISO code, e.g. "CHF". `nil` for points.
    public var currencyCode: String? {
        guard case .currency(let code) = self else { return nil }
        return code
    }
}

/// One short text in a stored file: "points" or the ISO code. An ISO code
/// has three capital letters, so it cannot be "points".
extension PriceUnit: Codable {
    private static let pointsText = "points"

    public init(from decoder: Decoder) throws {
        let text = try decoder.singleValueContainer().decode(String.self)
        self = text == Self.pointsText ? .points : .currency(text)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(currencyCode ?? Self.pointsText)
    }
}
