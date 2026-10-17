/// The table columns that the voice reads after the name. The name is
/// always read. The raw value is stored, so do not change the bits.
public struct SpokenColumns: OptionSet, Sendable, Hashable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let price = SpokenColumns(rawValue: 1 << 0)
    public static let day = SpokenColumns(rawValue: 1 << 1)
    /// The column of `RangeMode`.
    public static let shortRange = SpokenColumns(rawValue: 1 << 2)
    /// The column of `OneYearMode`.
    public static let longRange = SpokenColumns(rawValue: 1 << 3)

    /// The key of the stored choice in the user defaults.
    public static let storageKey = "spokenColumns"
    /// A new install reads the price and the day, as the app did before.
    public static let standard: SpokenColumns = [.price, .day]
}
