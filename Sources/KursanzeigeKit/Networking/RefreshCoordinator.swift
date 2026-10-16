import Foundation

/// Fetches fresh performance data for a batch of instruments with a
/// bounded number of requests in flight at once (Yahoo's unofficial
/// endpoint starts returning 429s under high concurrency), and reports
/// fractional progress as each one finishes. It also returns the price
/// history of each fetched instrument, for the chart.
struct RefreshCoordinator {
    let fetcher: PriceFetching
    let maxConcurrency: Int
    let calendar: Calendar

    init(fetcher: PriceFetching, maxConcurrency: Int = 4, calendar: Calendar = .current) {
        self.fetcher = fetcher
        self.maxConcurrency = maxConcurrency
        self.calendar = calendar
    }

    func refresh(
        _ instruments: [Instrument],
        asOf referenceDate: Date,
        onProgress: @escaping @Sendable (Double) -> Void
    ) async -> RefreshResult {
        guard !instruments.isEmpty else {
            onProgress(1.0)
            return RefreshResult(rows: [], histories: [:], failures: [])
        }

        var rows: [InstrumentRow] = []
        var histories: [String: PriceHistory] = [:]
        var failures: [FetchFailure] = []
        var completed = 0
        let total = instruments.count

        // Each `addTask` call is directly in this closure. A nested
        // function that captures `group` adds the tasks to a copy of the
        // group in a Release build. The group then ends at once, and the
        // app crashes when a task finishes.
        await withTaskGroup(of: (Instrument, Result<FetchedCloses, Error>).self) { group in
            var pending = instruments.makeIterator()
            for _ in 0..<maxConcurrency {
                guard let instrument = pending.next() else { break }
                group.addTask { await fetchResult(for: instrument) }
            }

            while let (instrument, result) = await group.next() {
                switch result {
                case .success(let fetched):
                    let history = PriceHistory(closes: fetched.closes, unit: fetched.unit, fetchedAt: referenceDate)
                    let changes = PerformanceCalculator.changes(closes: history.closes, asOf: referenceDate, calendar: calendar)
                    rows.append(.combining(instrument, changes, unit: fetched.unit))
                    histories[instrument.symbol] = history
                case .failure(let error):
                    failures.append(FetchFailure(symbol: instrument.symbol, error: (error as? FetchError) ?? .network))
                }
                completed += 1
                onProgress(Double(completed) / Double(total))
                if let next = pending.next() {
                    group.addTask { await fetchResult(for: next) }
                }
            }
        }

        return RefreshResult(rows: rows, histories: histories, failures: failures)
    }

    /// Gives the error as a value, so one failed symbol does not stop the
    /// other fetches.
    private func fetchResult(for instrument: Instrument) async -> (Instrument, Result<FetchedCloses, Error>) {
        do {
            return (instrument, .success(try await fetcher.fetchCloses(for: instrument.symbol)))
        } catch {
            return (instrument, .failure(error))
        }
    }
}
