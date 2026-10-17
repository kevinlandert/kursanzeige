/// What the rightmost column shows: the trailing 12 months, or the change
/// since the start of the calendar year. A single app-wide toggle (not
/// per-row) -- switching it relabels the column and changes what it sorts
/// and displays for every row at once.
public enum OneYearMode: Sendable, Equatable {
    case trailing
    case yearToDate

    /// The short name in the table header, e.g. „YTD“.
    public var headerTitle: String {
        self == .trailing ? "1-Jahr" : "YTD"
    }

    /// The name on the range button of the settings.
    public var choiceTitle: String {
        self == .trailing ? "1 Jahr" : "YTD"
    }

    /// The name that the voice says before the change. The voice would
    /// spell the letters of the English „YTD“.
    public var spokenName: String {
        self == .trailing ? "1 Jahr" : "seit Jahresbeginn"
    }
}
