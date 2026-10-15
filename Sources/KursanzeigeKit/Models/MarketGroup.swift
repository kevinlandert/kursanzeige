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

    /// The group before or after this one, in the order of the buttons.
    /// `nil` at the first and the last group: a swipe does not go around.
    public func neighbor(_ step: PageStep) -> MarketGroup? {
        let groups = Self.allCases
        guard let index = groups.firstIndex(of: self) else { return nil }
        let neighborIndex = step == .next ? index + 1 : index - 1
        return groups.indices.contains(neighborIndex) ? groups[neighborIndex] : nil
    }
}
