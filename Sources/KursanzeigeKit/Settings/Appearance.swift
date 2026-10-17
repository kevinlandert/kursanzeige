/// The setting „Erscheinungsbild“: a light app, a dark app, or an app that
/// follows the light or dark mode of the iPad. The raw value is the stored
/// text, so do not change it.
public enum Appearance: String, Sendable, CaseIterable {
    case light
    case dark
    /// „Wie iPad“: the app follows the Control Center or the automatic switch at night.
    case device

    /// The key of the stored choice in the user defaults.
    public static let storageKey = "appearance"
    /// The appearance of a new install.
    public static let standard = Appearance.light

    /// The name in the settings, for example „Wie iPad“.
    public var displayName: String {
        switch self {
        case .light: "Hell"
        case .dark: "Dunkel"
        case .device: "Wie iPad"
        }
    }

    /// The line under the choices. „Wie iPad“ tells the mode of the iPad now.
    public func hint(isDeviceDark: Bool) -> String {
        switch self {
        case .light: "Die App bleibt hell."
        case .dark: "Die App bleibt dunkel."
        case .device: "Die App folgt dem iPad. Jetzt: \(isDeviceDark ? "dunkel" : "hell")."
        }
    }
}
