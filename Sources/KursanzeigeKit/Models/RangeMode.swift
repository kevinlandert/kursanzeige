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

    /// The name on the range button of the settings, the same as on the
    /// range button of the chart.
    public var choiceTitle: String {
        chartRange.displayName
    }

    /// The name that the voice says before the change, e.g. „ein Monat“.
    public var spokenName: String {
        chartRange.spokenName
    }

    /// The chart range with the same span.
    private var chartRange: ChartRange {
        self == .oneMonth ? .oneMonth : .threeMonths
    }
}
