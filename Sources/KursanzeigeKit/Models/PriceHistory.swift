import Foundation

/// The daily closes of one instrument, and the time they were fetched.
/// "Aktualisieren" stores one per instrument. The table computes its
/// percent changes from it, and the chart shows it, so their numbers agree.
/// Internal: the app gets it only through `InstrumentChartViewModel`.
struct PriceHistory: Codable, Equatable, Sendable {
    /// Sorted oldest to newest.
    let closes: [ClosePoint]
    /// See `FetchedCloses.currency`.
    let currency: String?
    let fetchedAt: Date

    init(closes: [ClosePoint], currency: String? = nil, fetchedAt: Date) {
        self.closes = closes.sorted { $0.date < $1.date }
        self.currency = currency
        self.fetchedAt = fetchedAt
    }

    /// Sorts the closes again, because a stored file is external data. A
    /// file from an older version of the app has no currency.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            closes: try container.decode([ClosePoint].self, forKey: .closes),
            currency: try container.decodeIfPresent(String.self, forKey: .currency),
            fetchedAt: try container.decode(Date.self, forKey: .fetchedAt)
        )
    }

    /// The closes a chart of `range` shows. The first close is the last one
    /// on or before the range start: the same base close that
    /// `PerformanceCalculator` uses. Thus the chart's change from first to
    /// last close equals the table's change for that period. A history that
    /// starts after the range start gives all its closes. The table shows
    /// "–" for that period, but the chart still shows the line it has.
    func closes(in range: ChartRange, calendar: Calendar = .current) -> [ClosePoint] {
        let start = range.startDate(endingAt: fetchedAt, calendar: calendar)
        guard let firstIndex = closes.lastIndex(onOrBefore: start) else { return closes }
        return Array(closes[firstIndex...])
    }
}
