/// The setting „Sprechtempo“. The raw value is the stored text, so do not
/// change it.
public enum SpeechRate: String, Sendable, CaseIterable {
    case slow
    case normal
    case fast

    /// The key of the stored choice in the user defaults.
    public static let storageKey = "speechRate"
    /// The tempo of a new install.
    public static let standard = SpeechRate.normal

    /// The name in the settings, for example „Normal“.
    public var displayName: String {
        switch self {
        case .slow: "Langsam"
        case .normal: "Normal"
        case .fast: "Schnell"
        }
    }

    /// The factor on the default rate of the iOS voice.
    public var factor: Float {
        switch self {
        case .slow: 0.91
        case .normal: 1.0
        case .fast: 1.1
        }
    }

    /// The tempo of „Langsamer“. Nil at the slowest tempo.
    public var slowerRate: SpeechRate? {
        findNeighbor(offset: -1)
    }

    /// The tempo of „Schneller“. Nil at the fastest tempo.
    public var fasterRate: SpeechRate? {
        findNeighbor(offset: 1)
    }

    private func findNeighbor(offset: Int) -> SpeechRate? {
        let rates = Self.allCases
        guard let index = rates.firstIndex(of: self) else { return nil }
        let neighborIndex = index + offset
        return rates.indices.contains(neighborIndex) ? rates[neighborIndex] : nil
    }
}
