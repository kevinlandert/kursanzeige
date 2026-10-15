import Foundation

/// Turns a raw series of daily closes into the three percent changes shown
/// in a table row (day, 3-month, 1-year), each measured relative to a
/// reference date -- normally "now", but injectable for testing.
///
/// Targets ("3 months ago", "1 year ago") are calendar dates, not trading-day
/// counts, so weekends and holidays fall back to the closest prior close.
/// This keeps FX pairs (which trade weekends with gaps) and equities
/// (closed weekends/holidays) consistent without special-casing either.
enum PerformanceCalculator {
    static func changes(
        closes: [ClosePoint],
        asOf referenceDate: Date,
        calendar: Calendar = .current
    ) -> PerformanceChanges {
        let sorted = closes.sorted { $0.date < $1.date }

        guard let latestIndex = sorted.lastIndex(onOrBefore: referenceDate) else {
            return .empty
        }
        let latest = sorted[latestIndex]

        let dayChange = latestIndex > 0
            ? percentChange(from: sorted[latestIndex - 1].close, to: latest.close)
            : nil

        let oneMonthTarget = calendar.date(byAdding: .month, value: -1, to: referenceDate) ?? referenceDate
        let threeMonthTarget = calendar.date(byAdding: .month, value: -3, to: referenceDate) ?? referenceDate
        let oneYearTarget = calendar.date(byAdding: .year, value: -1, to: referenceDate) ?? referenceDate
        // Start of the reference date's calendar year -- there's never a
        // close exactly on Jan 1st (it's a holiday everywhere), so this
        // relies on the same "closest prior close" fallback as the other
        // targets to land on the last trading day of the previous year.
        let startOfYearTarget = calendar.date(from: calendar.dateComponents([.year], from: referenceDate)) ?? referenceDate

        return PerformanceChanges(
            latestPrice: latest.close,
            asOf: latest.date,
            dayChangePercent: dayChange,
            oneMonthChangePercent: change(in: sorted, latestIndex: latestIndex, latestClose: latest.close, target: oneMonthTarget),
            threeMonthChangePercent: change(in: sorted, latestIndex: latestIndex, latestClose: latest.close, target: threeMonthTarget),
            oneYearChangePercent: change(in: sorted, latestIndex: latestIndex, latestClose: latest.close, target: oneYearTarget),
            yearToDateChangePercent: change(in: sorted, latestIndex: latestIndex, latestClose: latest.close, target: startOfYearTarget)
        )
    }

    /// Percent change from the closest close on or before `target` to
    /// `latestClose`. Returns `nil` when there is no close old enough to
    /// serve as a base (not enough history) or the base would be the same
    /// point as the latest close (target landed after the last available data).
    private static func change(in sorted: [ClosePoint], latestIndex: Int, latestClose: Double, target: Date) -> Double? {
        guard let baseIndex = sorted.lastIndex(onOrBefore: target), baseIndex != latestIndex else {
            return nil
        }
        return percentChange(from: sorted[baseIndex].close, to: latestClose)
    }

    private static func percentChange(from base: Double, to value: Double) -> Double? {
        guard base != 0 else { return nil }
        return (value - base) / base * 100
    }
}
