import Testing
import Foundation
@testable import KursanzeigeKit

private let utcCalendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
}()

private let nestle = Instrument(symbol: "NESN.SW", name: "Nestlé", group: .switzerland)

private let fetchTime = utcCalendar.date(from: DateComponents(year: 2026, month: 10, day: 15))!

private func close(_ year: Int, _ month: Int, _ day: Int, _ value: Double) -> ClosePoint {
    ClosePoint(date: utcCalendar.date(from: DateComponents(year: year, month: month, day: day))!, close: value)
}

/// One close exactly on the start of the one-year and the three-month
/// range, and closes between them, so every range shows a different set.
private func createStoredHistory() -> PriceHistory {
    PriceHistory(
        closes: [
            close(2022, 3, 1, 10),
            close(2025, 10, 15, 40),
            close(2026, 4, 1, 50),
            close(2026, 7, 15, 90),
            close(2026, 9, 1, 80),
            close(2026, 10, 15, 65),
        ],
        fetchedAt: fetchTime
    )
}

/// Replays one result and counts its calls, so a test can check whether
/// the view model went to the network at all.
private actor CountingFetcher: PriceFetching {
    private let result: Result<[ClosePoint], FetchError>
    private(set) var callCount = 0

    init(_ result: Result<[ClosePoint], FetchError> = .success([])) {
        self.result = result
    }

    func fetchCloses(for symbol: String) async throws -> [ClosePoint] {
        callCount += 1
        switch result {
        case .success(let points): return points
        case .failure(let error): throw error
        }
    }
}

@MainActor
private func createViewModel(storedHistory: PriceHistory?, fetcher: PriceFetching) -> InstrumentChartViewModel {
    InstrumentChartViewModel(instrument: nestle, storedHistory: storedHistory, fetcher: fetcher, calendar: utcCalendar, now: { fetchTime })
}

@Suite("InstrumentChartViewModel")
@MainActor
struct InstrumentChartViewModelTests {
    @Test("defaults to the one-year range")
    func defaultsToOneYearRange() {
        let viewModel = createViewModel(storedHistory: createStoredHistory(), fetcher: CountingFetcher())

        #expect(viewModel.range == .oneYear)
    }

    @Test("a stored history shows its one-year closes at once")
    func storedHistoryShowsOneYearClosesAtOnce() {
        let viewModel = createViewModel(storedHistory: createStoredHistory(), fetcher: CountingFetcher())

        #expect(viewModel.points.map(\.close) == [40, 50, 90, 80, 65])
        #expect(viewModel.isLoading == false)
    }

    @Test("load does not fetch when a history is stored")
    func loadWithStoredHistoryDoesNotFetch() async {
        let fetcher = CountingFetcher()
        let viewModel = createViewModel(storedHistory: createStoredHistory(), fetcher: fetcher)

        await viewModel.load()

        #expect(await fetcher.callCount == 0)
        #expect(viewModel.points.map(\.close) == [40, 50, 90, 80, 65])
    }

    @Test("selecting a range shows that part of the stored history without a fetch")
    func selectingRangeCutsStoredHistory() async {
        let fetcher = CountingFetcher()
        let viewModel = createViewModel(storedHistory: createStoredHistory(), fetcher: fetcher)

        viewModel.select(.threeMonths)
        #expect(viewModel.points.map(\.close) == [90, 80, 65])

        viewModel.select(.fiveYears)
        #expect(viewModel.points.map(\.close) == [10, 40, 50, 90, 80, 65])

        #expect(viewModel.range == .fiveYears)
        #expect(await fetcher.callCount == 0)
    }

    @Test("a five-year chart shows a thinned line with the same change, high and low")
    func fiveYearChartShowsThinnedLine() {
        let dailyCloses = (0..<1_826).map { day in
            ClosePoint(date: utcCalendar.date(byAdding: .day, value: -day, to: fetchTime)!, close: 100 + Double(day % 13) + Double(day) / 50)
        }
        let history = PriceHistory(closes: dailyCloses, fetchedAt: fetchTime)
        let viewModel = createViewModel(storedHistory: history, fetcher: CountingFetcher())

        viewModel.select(.fiveYears)

        let allCloses = history.closes(in: .fiveYears, calendar: utcCalendar)
        #expect(viewModel.points.count <= InstrumentChartViewModel.maximumPointCount)
        #expect(viewModel.points.first == allCloses.first)
        #expect(viewModel.points.last == allCloses.last)
        #expect(viewModel.minClose == allCloses.map(\.close).min())
        #expect(viewModel.maxClose == allCloses.map(\.close).max())
    }

    @Test("the range change goes from the first to the last shown close")
    func rangeChangeGoesFromFirstToLastClose() {
        let viewModel = createViewModel(storedHistory: createStoredHistory(), fetcher: CountingFetcher())

        #expect(viewModel.rangeChangePercent == 62.5)
    }

    @Test("without closes there is no range change and nothing to read")
    func noClosesHaveNoRangeChangeAndNothingToRead() {
        let viewModel = createViewModel(storedHistory: nil, fetcher: CountingFetcher())

        #expect(viewModel.rangeChangePercent == nil)
        #expect(viewModel.spokenSummary(rangeName: "1 Jahr") == nil)
    }

    @Test("the spoken summary gives the name, the range, the last close and the range change")
    func spokenSummaryGivesNameRangeLastCloseAndChange() {
        let viewModel = createViewModel(storedHistory: createStoredHistory(), fetcher: CountingFetcher())

        #expect(viewModel.spokenSummary(rangeName: "1 Jahr") == "Nestlé, 1 Jahr, 65, plus 62,5 Prozent")
    }

    @Test("minClose and maxClose span only the shown range")
    func minAndMaxCloseSpanShownRange() {
        let viewModel = createViewModel(storedHistory: createStoredHistory(), fetcher: CountingFetcher())

        #expect(viewModel.minClose == 40)
        #expect(viewModel.maxClose == 90)
    }

    @Test("without a stored history, load fetches once and shows the closes")
    func loadWithoutStoredHistoryFetchesOnce() async {
        let fetcher = CountingFetcher(.success([close(2026, 10, 14, 100), close(2026, 10, 15, 101)]))
        let viewModel = createViewModel(storedHistory: nil, fetcher: fetcher)
        #expect(viewModel.points.isEmpty)

        await viewModel.load()

        #expect(await fetcher.callCount == 1)
        #expect(viewModel.points.map(\.close) == [100, 101])
        #expect(viewModel.isLoading == false)
    }

    @Test("a failed fetch shows a German error message and no points")
    func failedFetchSetsErrorMessage() async {
        let viewModel = createViewModel(storedHistory: nil, fetcher: CountingFetcher(.failure(.notFound)))

        await viewModel.load()

        #expect(viewModel.points.isEmpty)
        #expect(viewModel.minClose == nil)
        #expect(viewModel.errorMessage == "Symbol nicht gefunden")
        #expect(viewModel.isLoading == false)
    }

    @Test("a successful load after a failure clears the error")
    func successAfterFailureClearsError() async {
        let fetcher = SwitchingFetcher(firstResult: .failure(.network), secondResult: .success([close(2026, 10, 15, 100)]))
        let viewModel = createViewModel(storedHistory: nil, fetcher: fetcher)
        await viewModel.load()
        #expect(viewModel.errorMessage != nil)

        await viewModel.load()

        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.points.map(\.close) == [100])
    }

    @Test("a fetched history is handed to onFetched, so it can be stored")
    func fetchedHistoryIsHandedToOnFetched() async {
        let received = HistoryLog()
        let viewModel = InstrumentChartViewModel(
            instrument: nestle,
            storedHistory: nil,
            fetcher: CountingFetcher(.success([close(2026, 10, 15, 100)])),
            calendar: utcCalendar,
            now: { fetchTime },
            onFetched: { await received.record($0) }
        )

        await viewModel.load()

        #expect(await received.histories == [PriceHistory(closes: [close(2026, 10, 15, 100)], fetchedAt: fetchTime)])
    }

    @Test("a second load while a fetch is in flight does not fetch again")
    func secondLoadDuringFetchDoesNotFetchAgain() async {
        let fetcher = ManualFetcher()
        let viewModel = createViewModel(storedHistory: nil, fetcher: fetcher)

        async let firstLoad: Void = viewModel.load()
        await fetcher.waitForFirstCall()
        await viewModel.load()
        await fetcher.resolve(.success([close(2026, 10, 15, 100)]))
        await firstLoad

        #expect(await fetcher.callCount == 1)
        #expect(viewModel.points.map(\.close) == [100])
    }
}

/// A `PriceFetching` whose `fetchCloses` call waits until the test resolves
/// it -- for keeping a fetch in flight while the test acts.
private actor ManualFetcher: PriceFetching {
    private var continuation: CheckedContinuation<[ClosePoint], Error>?
    private(set) var callCount = 0

    func fetchCloses(for symbol: String) async throws -> [ClosePoint] {
        callCount += 1
        return try await withCheckedThrowingContinuation { continuation = $0 }
    }

    func resolve(_ result: Result<[ClosePoint], FetchError>) {
        switch result {
        case .success(let points): continuation?.resume(returning: points)
        case .failure(let error): continuation?.resume(throwing: error)
        }
        continuation = nil
    }

    /// Polls until the first fetch has started -- avoids a fixed delay
    /// that races against actor scheduling.
    func waitForFirstCall() async {
        while continuation == nil {
            await Task.yield()
        }
    }
}

/// Returns `firstResult` on the first call and `secondResult` on every call
/// after that -- for tests of a reload after an earlier failure.
private actor SwitchingFetcher: PriceFetching {
    private let firstResult: Result<[ClosePoint], FetchError>
    private let secondResult: Result<[ClosePoint], FetchError>
    private var callCount = 0

    init(firstResult: Result<[ClosePoint], FetchError>, secondResult: Result<[ClosePoint], FetchError>) {
        self.firstResult = firstResult
        self.secondResult = secondResult
    }

    func fetchCloses(for symbol: String) async throws -> [ClosePoint] {
        callCount += 1
        let result = callCount == 1 ? firstResult : secondResult
        switch result {
        case .success(let points): return points
        case .failure(let error): throw error
        }
    }
}

/// Keeps every history that `onFetched` receives.
private actor HistoryLog {
    private(set) var histories: [PriceHistory] = []

    func record(_ history: PriceHistory) {
        histories.append(history)
    }
}
