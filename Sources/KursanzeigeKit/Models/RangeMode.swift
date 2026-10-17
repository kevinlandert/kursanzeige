/// What the 3-Monate column shows: the trailing 1 month, or the trailing
/// 3 months. A single app-wide toggle (not per-row), same pattern as
/// `OneYearMode`.
public enum RangeMode: Sendable, Equatable {
    case oneMonth
    case threeMonth

    /// The short name in the table header, e.g. „1-Mt.“.
    public var headerTitle: String {
        self == .oneMonth ? "1-Mt." : "3-Mt."
    }

    /// The name on the range button of the settings.
    public var choiceTitle: String {
        spokenName
    }

    /// The name that the voice says before the change, e.g. „1 Monat“.
    public var spokenName: String {
        self == .oneMonth ? "1 Monat" : "3 Monate"
    }
}
