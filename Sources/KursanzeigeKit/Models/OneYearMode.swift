import Foundation

/// What the rightmost column shows: the trailing 12 months, or the change
/// since the start of the calendar year. A single app-wide toggle (not
/// per-row) -- switching it relabels the column and changes what it sorts
/// and displays for every row at once. Display strings for each case live
/// in the view layer, alongside the rest of the app's German labels.
public enum OneYearMode: Sendable, Equatable {
    case trailing
    case yearToDate
}
