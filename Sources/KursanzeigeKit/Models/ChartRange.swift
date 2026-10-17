import Foundation

/// How far back the instrument chart overlay's line goes. A single
/// per-chart toggle -- picking a new range cuts a different part of the
/// stored price history, with no new fetch. The voice and the range
/// buttons use the same `displayName`.
/// The case order is the order of the range buttons, shortest first.
public enum ChartRange: CaseIterable, Sendable, Hashable {
    case oneMonth
    case threeMonths
    case oneYear
    case fiveYears

    /// The German label of the range button, e.g. „1 Jahr“.
    public var displayName: String {
        switch self {
        case .oneMonth: "1 Monat"
        case .threeMonths: "3 Monate"
        case .oneYear: "1 Jahr"
        case .fiveYears: "5 Jahre"
        }
    }

    /// The first day of this range, counted back from `end` in calendar
    /// months or years -- the same targets `PerformanceCalculator` uses.
    func startDate(endingAt end: Date, calendar: Calendar) -> Date {
        let (component, value): (Calendar.Component, Int) = switch self {
        case .oneMonth: (.month, -1)
        case .threeMonths: (.month, -3)
        case .oneYear: (.year, -1)
        case .fiveYears: (.year, -5)
        }
        return calendar.date(byAdding: component, value: value, to: end) ?? end
    }
}
