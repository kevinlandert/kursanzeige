import Foundation

/// The percent changes shown in one table row, computed from a series of
/// daily closes relative to a reference date (normally "now").
///
/// Each change is `nil` when there isn't enough price history to compute
/// it (e.g. an instrument that started trading less than a year ago), and
/// the view renders `nil` as a plain "–" rather than 0%.
struct PerformanceChanges: Equatable {
    /// The most recent close price found at or before the reference date.
    let latestPrice: Double?
    /// The date of `latestPrice`.
    let asOf: Date?
    /// Percent change vs. the previous available close.
    let dayChangePercent: Double?
    /// Percent change vs. the close on or before (reference date - 1 month).
    let oneMonthChangePercent: Double?
    /// Percent change vs. the close on or before (reference date - 3 months).
    let threeMonthChangePercent: Double?
    /// Percent change vs. the close on or before (reference date - 1 year).
    let oneYearChangePercent: Double?
    /// Percent change vs. the close on or before January 1st of the
    /// reference date's year -- i.e. the last close of the prior year.
    let yearToDateChangePercent: Double?

    static let empty = PerformanceChanges(
        latestPrice: nil,
        asOf: nil,
        dayChangePercent: nil,
        oneMonthChangePercent: nil,
        threeMonthChangePercent: nil,
        oneYearChangePercent: nil,
        yearToDateChangePercent: nil
    )
}
