import Foundation

/// A single tradeable instrument (stock, currency pair, ETF, or index)
/// that appears in one of the market groups.
///
/// `symbol` is the Yahoo Finance ticker used to fetch prices; `name` is the
/// short display name shown in the table. Names are curated by hand rather
/// than taken from Yahoo's `shortName`/`longName`, because those are often
/// too long or too all-caps to read comfortably at large font sizes.
public struct Instrument: Codable, Equatable, Identifiable, Hashable, Sendable {
    public let symbol: String
    public let name: String
    public let group: MarketGroup
    /// `false` marks an entry retired from `constituents.json` without
    /// deleting it -- JSON has no comment syntax, so this is how a removed
    /// instrument stays visible (and easy to bring back) in source control
    /// instead of vanishing from the diff entirely. `Constituents.load`
    /// filters these out before they ever reach the app.
    public let enabled: Bool

    public var id: String { symbol }

    /// The character range every real Yahoo Finance ticker in this app
    /// uses: letters, digits, and "-.^=" (e.g. "BRK-B", "NESN.SW",
    /// "^GSPC", "CHF=X"). Shared with `YahooFinanceClient`'s URL-encoding
    /// so a symbol is validated and percent-encoded against the same
    /// definition rather than two hand-kept lists drifting apart -- and so
    /// a symbol typed into the "add instrument" field can't smuggle a "/"
    /// (or any other character) into the request path built from it.
    public static let validSymbolCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-.^="))

    /// Whether `symbol` contains only characters a real ticker ever uses.
    /// Empty is not "valid" here -- callers still need their own blank check.
    public static func isValidSymbol(_ symbol: String) -> Bool {
        !symbol.isEmpty && symbol.unicodeScalars.allSatisfy(validSymbolCharacters.contains)
    }

    public init(symbol: String, name: String, group: MarketGroup, enabled: Bool = true) {
        self.symbol = symbol
        self.name = name
        self.group = group
        self.enabled = enabled
    }

    private enum CodingKeys: String, CodingKey {
        case symbol, name, group, enabled
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        symbol = try container.decode(String.self, forKey: .symbol)
        name = try container.decode(String.self, forKey: .name)
        group = try container.decode(MarketGroup.self, forKey: .group)
        enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled) ?? true
    }
}
