/// A width and a height in points.
public struct ChartSize: Equatable, Sendable {
    public let width: Double
    public let height: Double

    public init(width: Double, height: Double) {
        self.width = width
        self.height = height
    }
}

/// The size of the chart in the free space of the chart page. The ratio of
/// a chart sets how steep a move looks. Without a rule, a portrait chart is
/// almost square and a landscape chart is three times as wide as high, so
/// the same move looks steep in one and flat in the other.
public enum ChartShape {
    /// Wider than high, as usual for prices over time.
    static let smallestRatio = 1.5
    static let largestRatio = 2.0

    /// The largest size in the space with a width to height ratio from 1.5
    /// to 2. A space that is too high gives a lower chart. A space that is
    /// too wide gives a narrower chart.
    public static func fit(width: Double, height: Double) -> ChartSize {
        guard width > 0, height > 0 else { return ChartSize(width: 0, height: 0) }
        let ratio = width / height
        if ratio < smallestRatio {
            return ChartSize(width: width, height: width / smallestRatio)
        }
        if ratio > largestRatio {
            return ChartSize(width: height * largestRatio, height: height)
        }
        return ChartSize(width: width, height: height)
    }
}
