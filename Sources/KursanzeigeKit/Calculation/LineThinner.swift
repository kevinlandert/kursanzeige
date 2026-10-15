import Foundation

/// Thins a long price line, so a thick chart line shows the trend and not
/// a scribble of daily moves. It uses Largest-Triangle-Three-Buckets
/// (Steinarsson, 2013): it splits the closes into buckets and keeps the
/// close of each bucket that changes the shape of the line most. Thus a
/// sharp drop stays visible. It always keeps the first, last, highest and
/// lowest close, so the range change and the axis labels stay correct.
/// Every kept point is a real close. Nothing is averaged.
enum LineThinner {
    /// `closes` must be sorted oldest to newest. Gives `closes` unchanged
    /// if it has no more than `maximumCount` closes, or if `maximumCount`
    /// is below 5: the first, last, highest and lowest close need 4 places.
    static func thin(_ closes: [ClosePoint], toAtMost maximumCount: Int) -> [ClosePoint] {
        // Two places stay free for the highest and the lowest close.
        let bucketedCount = maximumCount - 2
        guard closes.count > maximumCount, bucketedCount >= 3 else { return closes }

        let keptIndices = Set(largestTriangleIndices(of: closes, count: bucketedCount))
            .union(extremeIndices(of: closes))
        return keptIndices.sorted().map { closes[$0] }
    }

    /// The first and last index, plus one index per bucket in between.
    /// Each bucket keeps the close that makes the largest triangle with the
    /// close kept before it and the average of the next bucket.
    private static func largestTriangleIndices(of closes: [ClosePoint], count: Int) -> [Int] {
        let bucketCount = count - 2
        let bucketSize = Double(closes.count - 2) / Double(bucketCount)
        let lastIndex = closes.count - 1
        var keptIndices = [0]

        for bucket in 0..<bucketCount {
            let candidates = bucketRange(bucket, size: bucketSize, lastIndex: lastIndex)
            let nextBucket = bucket + 1 < bucketCount
                ? bucketRange(bucket + 1, size: bucketSize, lastIndex: lastIndex)
                : lastIndex..<(lastIndex + 1)
            let previous = PlotPoint(closes[keptIndices[keptIndices.count - 1]])
            let next = PlotPoint.average(of: closes[nextBucket])
            let best = candidates.max { first, second in
                triangleArea(previous, PlotPoint(closes[first]), next) < triangleArea(previous, PlotPoint(closes[second]), next)
            }
            keptIndices.append(best ?? candidates.lowerBound)
        }
        return keptIndices + [lastIndex]
    }

    /// The indices of one bucket. The buckets share the closes between the
    /// first and the last one, and each holds at least one close.
    private static func bucketRange(_ bucket: Int, size: Double, lastIndex: Int) -> Range<Int> {
        let start = Int(Double(bucket) * size) + 1
        let end = min(Int(Double(bucket + 1) * size) + 1, lastIndex)
        return start..<max(end, start + 1)
    }

    private static func extremeIndices(of closes: [ClosePoint]) -> [Int] {
        let byClose: (Int, Int) -> Bool = { closes[$0].close < closes[$1].close }
        return [closes.indices.min(by: byClose), closes.indices.max(by: byClose)].compactMap { $0 }
    }

    private static func triangleArea(_ first: PlotPoint, _ second: PlotPoint, _ third: PlotPoint) -> Double {
        abs((first.x - third.x) * (second.y - first.y) - (first.x - second.x) * (third.y - first.y)) / 2
    }
}

/// A close as a point on the plot: seconds on the x-axis, price on the
/// y-axis. The two scales differ, but that does not change which close
/// in a bucket makes the largest triangle.
private struct PlotPoint {
    let x: Double
    let y: Double

    init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    init(_ close: ClosePoint) {
        self.init(x: close.date.timeIntervalSince1970, y: close.close)
    }

    static func average(of closes: ArraySlice<ClosePoint>) -> PlotPoint {
        let count = Double(closes.count)
        return PlotPoint(
            x: closes.map { $0.date.timeIntervalSince1970 }.reduce(0, +) / count,
            y: closes.map(\.close).reduce(0, +) / count
        )
    }
}
