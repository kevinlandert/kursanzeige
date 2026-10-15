import Foundation

/// How far back the instrument chart overlay's line goes. A single
/// per-chart toggle -- picking a new range cuts a different part of the
/// stored price history, with no new fetch. Display strings live in the
/// view layer, same pattern as `OneYearMode`/`RangeMode`.
public enum ChartRange: CaseIterable, Sendable, Hashable {
    case threeMonths
    case oneYear
    case fiveYears

    /// The first day of this range, counted back from `end` in calendar
    /// months or years -- the same targets `PerformanceCalculator` uses.
    func startDate(endingAt end: Date, calendar: Calendar) -> Date {
        let (component, value): (Calendar.Component, Int) = switch self {
        case .threeMonths: (.month, -3)
        case .oneYear: (.year, -1)
        case .fiveYears: (.year, -5)
        }
        return calendar.date(byAdding: component, value: value, to: end) ?? end
    }
}
