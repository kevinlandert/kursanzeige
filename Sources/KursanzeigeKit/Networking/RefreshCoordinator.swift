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

        await withTaskGroup(of: (Instrument, Result<[ClosePoint], Error>).self) { group in
            var pending = instruments[...]

            func startNext() {
                guard let instrument = pending.first else { return }
                pending = pending.dropFirst()
                group.addTask {
                    do {
                        return (instrument, .success(try await fetcher.fetchCloses(for: instrument.symbol)))
                    } catch {
                        return (instrument, .failure(error))
                    }
                }
            }

            for _ in 0..<min(maxConcurrency, instruments.count) {
                startNext()
            }

            while let (instrument, result) = await group.next() {
                switch result {
                case .success(let closes):
                    let history = PriceHistory(closes: closes, fetchedAt: referenceDate)
                    let changes = PerformanceCalculator.changes(closes: history.closes, asOf: referenceDate, calendar: calendar)
                    rows.append(.combining(instrument, changes))
                    histories[instrument.symbol] = history
                case .failure(let error):
                    failures.append(FetchFailure(symbol: instrument.symbol, error: (error as? FetchError) ?? .network))
                }
                completed += 1
                onProgress(Double(completed) / Double(total))
                startNext()
            }
        }

        return RefreshResult(rows: rows, histories: histories, failures: failures)
    }
}
