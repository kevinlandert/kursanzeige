/// Light or dark display of the full app. The button next to the settings
/// button changes it. The raw value is the stored text, so the choice
/// stays after the app closes.
public enum Appearance: String, Sendable {
    case light
    case dark

    /// The key of the stored choice in the user defaults.
    public static let storageKey = "appearance"

    public var toggled: Appearance {
        self == .light ? .dark : .light
    }
}
