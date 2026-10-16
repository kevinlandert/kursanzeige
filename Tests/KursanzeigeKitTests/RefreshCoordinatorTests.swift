import Testing
import Foundation
@testable import KursanzeigeKit

/// Fake fetcher used by RefreshCoordinator tests: succeeds for every symbol
/// not in `failingSymbols`, and can track peak concurrent in-flight calls
/// via a tiny artificial delay.
private actor TrackingFetcher: PriceFetching {
    let failingSymbols: Set<String>
    let delayNanoseconds: UInt64
    let unit: PriceUnit?
    private var inFlight = 0
    private(set) var peakInFlight = 0

    init(failingSymbols: Set<String> = [], delayNanoseconds: UInt64 = 0, unit: PriceUnit? = nil) {
        self.failingSymbols = failingSymbols
        self.delayNanoseconds = delayNanoseconds
        self.unit = unit
    }

    func fetchCloses(for symbol: String) async throws -> FetchedCloses {
        inFlight += 1
        peakInFlight = max(peakInFlight, inFlight)
        if delayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: delayNanoseconds)
        }
        inFlight -= 1
        if failingSymbols.contains(symbol) {
            throw FetchError.notFound
        }
        return FetchedCloses(closes: [ClosePoint(date: Date(), close: 100)], unit: unit)
    }
}

/// Thread-safe accumulator for progress callbacks fired from concurrent tasks.
private final class ProgressLog: @unchecked Sendable {
    private var values: [Double] = []
    private let lock = NSLock()

    func record(_ value: Double) {
        lock.lock()
        values.append(value)
        lock.unlock()
    }

    var recorded: [Double] {
        lock.lock()
        defer { lock.unlock() }
        return values
    }
}

private func makeInstruments(_ count: Int) -> [Instrument] {
    (0..<count).map { Instrument(symbol: "SYM\($0)", name: "Name \($0)", group: .switzerland) }
}

struct RefreshCoordinatorTests {

    @Test func allSuccessfulProducesRowForEveryInstrumentAndNoFailures() async {
        let instruments = makeInstruments(5)
        let coordinator = RefreshCoordinator(fetcher: TrackingFetcher(), maxConcurrency: 4)
        let log = ProgressLog()

        let result = await coordinator.refresh(instruments, asOf: Date()) { log.record($0) }

        #expect(result.rows.count == 5)
        #expect(result.failures.isEmpty)
        #expect(log.recorded.last == 1.0)
    }

    @Test("the fetched unit goes to the row and to the history")
    func fetchedUnitGoesToRowAndHistory() async {
        let instruments = makeInstruments(1)
        let coordinator = RefreshCoordinator(fetcher: TrackingFetcher(unit: .currency("CHF")))

        let result = await coordinator.refresh(instruments, asOf: Date()) { _ in }

        #expect(result.rows.first?.unit == .currency("CHF"))
        #expect(result.histories[instruments[0].symbol]?.unit == .currency("CHF"))
    }

    @Test func failedSymbolsAreReportedAndExcludedFromRows() async {
        let instruments = makeInstruments(4)
        let fetcher = TrackingFetcher(failingSymbols: ["SYM1", "SYM3"])
        let coordinator = RefreshCoordinator(fetcher: fetcher, maxConcurrency: 2)

        let result = await coordinator.refresh(instruments, asOf: Date()) { _ in }

        #expect(result.rows.count == 2)
        #expect(Set(result.failures.map(\.symbol)) == ["SYM1", "SYM3"])
        #expect(result.failures.allSatisfy { $0.error == .notFound })
    }

    @Test func progressReachesOneAndIsMonotonicallyNonDecreasing() async {
        let instruments = makeInstruments(6)
        let coordinator = RefreshCoordinator(fetcher: TrackingFetcher(), maxConcurrency: 3)
        let log = ProgressLog()

        _ = await coordinator.refresh(instruments, asOf: Date()) { log.record($0) }

        let values = log.recorded
        #expect(values.count == 6)
        #expect(values == values.sorted())
        #expect(values.last == 1.0)
    }

    @Test func emptyInstrumentListReportsCompleteImmediately() async {
        let coordinator = RefreshCoordinator(fetcher: TrackingFetcher(), maxConcurrency: 4)
        let log = ProgressLog()

        let result = await coordinator.refresh([], asOf: Date()) { log.record($0) }

        #expect(result.rows.isEmpty)
        #expect(log.recorded == [1.0])
    }

    @Test func eachSuccessfulFetchKeepsItsPriceHistoryWithTheRefreshTime() async {
        let instruments = makeInstruments(3)
        let refreshTime = Date(timeIntervalSince1970: 1_700_000_000)
        let coordinator = RefreshCoordinator(fetcher: TrackingFetcher(failingSymbols: ["SYM1"]), maxConcurrency: 2)

        let result = await coordinator.refresh(instruments, asOf: refreshTime) { _ in }

        #expect(Set(result.histories.keys) == ["SYM0", "SYM2"])
        #expect(result.histories["SYM0"]?.closes.map(\.close) == [100])
        #expect(result.histories.values.allSatisfy { $0.fetchedAt == refreshTime })
    }

    @Test func neverExceedsMaxConcurrency() async {
        let instruments = makeInstruments(10)
        let fetcher = TrackingFetcher(delayNanoseconds: 5_000_000) // 5ms, enough to force overlap
        let coordinator = RefreshCoordinator(fetcher: fetcher, maxConcurrency: 2)

        _ = await coordinator.refresh(instruments, asOf: Date()) { _ in }

        #expect(await fetcher.peakInFlight <= 2)
    }
}
