import Foundation

/// Sorts table rows by the tapped column. Rows with no value in the sorted
/// column (no data yet, or not enough history) always sink to the bottom,
/// in either direction, so a low-vision user doesn't have to search past
/// blank rows to find the ranked data. Ties (including "both nil") fall
/// back to name order for a stable, predictable list.
enum InstrumentSorter {
    /// `oneYearMode` decides which value the `.oneYear` column sorts by --
    /// trailing 12 months or year-to-date -- matching whichever one is
    /// currently displayed there, so sorting never contradicts what's on
    /// screen. `rangeMode` does the same for the `.threeMonth` column
    /// (trailing 1 month or 3 months).
    static func sort(_ rows: [InstrumentRow], by state: SortState, oneYearMode: OneYearMode = .trailing, rangeMode: RangeMode = .threeMonth) -> [InstrumentRow] {
        rows.sorted { lhs, rhs in
            switch state.column {
            case .name:
                let comparison = lhs.instrument.name.localizedCompare(rhs.instrument.name)
                if comparison != .orderedSame {
                    return state.ascending ? comparison == .orderedAscending : comparison == .orderedDescending
                }
                return false
            case .price:
                return compareNumeric(lhs.price, rhs.price, lhs, rhs, ascending: state.ascending)
            case .day:
                return compareNumeric(lhs.dayChangePercent, rhs.dayChangePercent, lhs, rhs, ascending: state.ascending)
            case .threeMonth:
                let lhsValue = rangeMode == .threeMonth ? lhs.threeMonthChangePercent : lhs.oneMonthChangePercent
                let rhsValue = rangeMode == .threeMonth ? rhs.threeMonthChangePercent : rhs.oneMonthChangePercent
                return compareNumeric(lhsValue, rhsValue, lhs, rhs, ascending: state.ascending)
            case .oneYear:
                let lhsValue = oneYearMode == .trailing ? lhs.oneYearChangePercent : lhs.yearToDateChangePercent
                let rhsValue = oneYearMode == .trailing ? rhs.oneYearChangePercent : rhs.yearToDateChangePercent
                return compareNumeric(lhsValue, rhsValue, lhs, rhs, ascending: state.ascending)
            }
        }
    }

    /// `nil` values always sort after every present value, regardless of
    /// direction. When values tie (including "both nil"), falls back to
    /// name order so the result is stable and reproducible.
    private static func compareNumeric(_ lhs: Double?, _ rhs: Double?, _ lhsRow: InstrumentRow, _ rhsRow: InstrumentRow, ascending: Bool) -> Bool {
        switch (lhs, rhs) {
        case let (l?, r?):
            if l == r {
                return lhsRow.instrument.name.localizedCompare(rhsRow.instrument.name) == .orderedAscending
            }
            return ascending ? l < r : l > r
        case (nil, nil):
            return lhsRow.instrument.name.localizedCompare(rhsRow.instrument.name) == .orderedAscending
        case (nil, _):
            return false
        case (_, nil):
            return true
        }
    }
}
