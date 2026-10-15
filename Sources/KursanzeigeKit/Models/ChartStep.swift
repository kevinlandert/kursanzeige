import Foundation

/// One step from the shown chart to the chart of a neighbor row in the
/// table. "Vorheriger", "Nächster" and a sideways swipe each ask for one.
public enum ChartStep: Sendable, Equatable {
    case previous
    case next

    /// A swipe shorter than this does nothing, so a small slip of the
    /// finger on a range button does not change the chart.
    static let minimumSwipeDistance = 60.0

    /// The step of a swipe with this translation, in points. A swipe to
    /// the left shows the next row, as when one turns a page. `nil` for a
    /// short swipe, or one that goes more up or down than sideways.
    public init?(swipeWidth: Double, height: Double) {
        guard abs(swipeWidth) >= Self.minimumSwipeDistance, abs(swipeWidth) > abs(height) else { return nil }
        self = swipeWidth < 0 ? .next : .previous
    }
}
