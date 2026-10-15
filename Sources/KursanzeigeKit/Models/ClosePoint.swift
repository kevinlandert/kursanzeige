import Foundation

/// A single daily closing price, after `null` entries from Yahoo's response
/// have been filtered out. Public so the chart view can plot the points
/// `InstrumentChartViewModel` shows, without exposing `PriceFetching` or
/// any other networking type.
public struct ClosePoint: Codable, Equatable, Sendable {
    public let date: Date
    public let close: Double

    public init(date: Date, close: Double) {
        self.date = date
        self.close = close
    }
}

extension Array where Element == ClosePoint {
    /// Index of the last close on or before `date`, in closes sorted oldest
    /// to newest. `nil` if every close is after `date`. The table and the
    /// chart both use this rule to find the base close of a period.
    func lastIndex(onOrBefore date: Date) -> Int? {
        lastIndex { $0.date <= date }
    }
}
