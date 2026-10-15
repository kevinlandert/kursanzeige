/// The place of the current price label on the right axis of the chart.
/// The label shows, except for a flat line. Near the high or the low
/// label, it moves away, so the large texts do not overlap. The text
/// stays the real price.
public enum CurrentPriceLabel {
    /// The axis value where the label sits. `minimumGapShare` is the
    /// smallest gap to the high and the low label, as a part of the
    /// high-low range. A share above 0.5 counts as 0.5: the label then
    /// sits in the middle. `nil` for a flat line: the high and low label
    /// then show the same price.
    public static func axisValue(current: Double, low: Double, high: Double, minimumGapShare: Double) -> Double? {
        let range = high - low
        guard range > 0 else { return nil }
        let minimumGap = range * min(minimumGapShare, 0.5)
        return min(max(current, low + minimumGap), high - minimumGap)
    }
}
