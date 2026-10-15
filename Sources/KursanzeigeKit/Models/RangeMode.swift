import Foundation

/// What the 3-Monate column shows: the trailing 1 month, or the trailing
/// 3 months. A single app-wide toggle (not per-row), same pattern as
/// `OneYearMode`. Display strings for each case live in the view layer.
public enum RangeMode: Sendable, Equatable {
    case oneMonth
    case threeMonth
}
