import Foundation

/// The selectable groups of constituents shown in the group selector.
/// Order here is display order, left to right.
public enum MarketGroup: String, CaseIterable, Codable, Identifiable, Sendable {
    case index = "Index"
    case currencies = "Währungen"
    case switzerland = "Schweiz"
    case usa = "USA"
    case europe = "Europa"
    case world = "Welt"

    public var id: String { rawValue }

    /// Short label used on the selector button. Same as rawValue today,
    /// kept separate so the button label can diverge from the raw value
    /// used for JSON decoding without a breaking change.
    public var displayName: String { rawValue }
}
