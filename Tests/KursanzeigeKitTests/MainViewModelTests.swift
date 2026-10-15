import Testing
import Foundation
@testable import KursanzeigeKit

/// Replays scripted results per symbol; missing scripts throw `.network`.
private actor ScriptedFetcher: PriceFetching {
    private var scripts: [String: Result<[ClosePoint], FetchError>]

    init(scripts: [String: Result<[ClosePoint], FetchError>]) {
        self.scripts = scripts
    }

    func fetchCloses(for symbol: String) async throws -> [ClosePoint] {
        switch scripts[symbol] {
        case .success(let points): return points
        case .failure(let error): throw error
        case nil: throw FetchError.network
        }
    }
}

private final class InMemoryCache: SnapshotCaching, @unchecked Sendable {
    private var stored: CachedSnapshot?
    private let lock = NSLock()

    init(initial: CachedSnapshot? = nil) { stored = initial }

    func load() -> CachedSnapshot? {
        lock.lock(); defer { lock.unlock() }
        return stored
    }

    func save(_ snapshot: CachedSnapshot) {
        lock.lock(); defer { lock.unlock() }
        stored = snapshot
    }
}

private final class InMemoryConstituentsStore: ConstituentsStoring, @unchecked Sendable {
    private var stored: [Instrument]?
    private let lock = NSLock()

    /// `nil` (the default) simulates a fresh install -- nothing persisted
    /// on this device yet.
    init(initial: [Instrument]? = nil) { stored = initial }

    func load() -> [Instrument]? {
        lock.lock(); defer { lock.unlock() }
        return stored
    }

    func save(_ instruments: [Instrument]) {
        lock.lock(); defer { lock.unlock() }
        stored = instruments
    }
}

private final class InMemoryPriceHistoryStore: PriceHistoryStoring, @unchecked Sendable {
    private var stored: [String: PriceHistory] = [:]
    private let lock = NSLock()

    func load(for symbol: String) -> PriceHistory? {
        lock.withLock { stored[symbol] }
    }

    func save(_ history: PriceHistory, for symbol: String) {
        lock.withLock { stored[symbol] = history }
    }
}

private let chf = Instrument(symbol: "EURCHF=X", name: "EUR/CHF", group: .currencies)
private let usdchf = Instrument(symbol: "USDCHF=X", name: "USD/CHF", group: .currencies)
private let nestle = Instrument(symbol: "NESN.SW", name: "Nestlé", group: .switzerland)
private let novartis = Instrument(symbol: "NOVN.SW", name: "Novartis", group: .switzerland)
private let testInstruments = [chf, usdchf, nestle, novartis]

private func points(_ close: Double) -> [ClosePoint] {
    [ClosePoint(date: Date(), close: close)]
}

@MainActor
struct MainViewModelTests {

    @Test func loadsCachedRowsOnInit() {
        let cachedRow = InstrumentRow(instrument: nestle, price: 77.96, asOf: Date(), dayChangePercent: 0.3, threeMonthChangePercent: -4.1, oneYearChangePercent: -12.8)
        let cache = InMemoryCache(initial: CachedSnapshot(rows: [cachedRow], savedAt: Date(timeIntervalSince1970: 1_700_000_000)))
        let viewModel = MainViewModel(instruments: testInstruments, fetcher: ScriptedFetcher(scripts: [:]), cache: cache)

        viewModel.select(.switzerland)

        #expect(viewModel.displayedRows.first { $0.instrument.symbol == "NESN.SW" }?.price == 77.96)
        #expect(viewModel.lastUpdated == Date(timeIntervalSince1970: 1_700_000_000))
    }

    @Test func selectingGroupFiltersDisplayedRows() {
        let viewModel = MainViewModel(instruments: testInstruments, fetcher: ScriptedFetcher(scripts: [:]), cache: InMemoryCache())

        viewModel.select(.currencies)
        #expect(Set(viewModel.displayedRows.map(\.instrument.symbol)) == ["EURCHF=X", "USDCHF=X"])

        viewModel.select(.switzerland)
        #expect(Set(viewModel.displayedRows.map(\.instrument.symbol)) == ["NESN.SW", "NOVN.SW"])
    }

    @Test func togglingSameColumnReversesDirection() {
        let viewModel = MainViewModel(instruments: testInstruments, fetcher: ScriptedFetcher(scripts: [:]), cache: InMemoryCache())
        viewModel.select(.switzerland)

        viewModel.toggleSort(.name)
        #expect(viewModel.sortColumn == .name)
        #expect(viewModel.sortAscending == true)
        #expect(viewModel.displayedRows.map(\.instrument.name) == ["Nestlé", "Novartis"])

        viewModel.toggleSort(.name)
        #expect(viewModel.sortAscending == false)
        #expect(viewModel.displayedRows.map(\.instrument.name) == ["Novartis", "Nestlé"])
    }

    @Test func togglingNewColumnResetsToAscending() {
        let viewModel = MainViewModel(instruments: testInstruments, fetcher: ScriptedFetcher(scripts: [:]), cache: InMemoryCache())
        viewModel.toggleSort(.name)
        viewModel.toggleSort(.name) // now descending

        viewModel.toggleSort(.price)
        #expect(viewModel.sortColumn == .price)
        #expect(viewModel.sortAscending == true)
    }

    @Test func oneYearModeDefaultsToTrailingAndToggles() {
        let viewModel = MainViewModel(instruments: testInstruments, fetcher: ScriptedFetcher(scripts: [:]), cache: InMemoryCache())
        #expect(viewModel.oneYearMode == .trailing)

        viewModel.toggleOneYearMode()
        #expect(viewModel.oneYearMode == .yearToDate)

        viewModel.toggleOneYearMode()
        #expect(viewModel.oneYearMode == .trailing)
    }

    @Test func togglingOneYearModeReSortsWhenOneYearColumnIsActive() {
        let highOneYear = InstrumentRow(instrument: nestle, price: 1, asOf: nil, dayChangePercent: nil, threeMonthChangePercent: nil, oneYearChangePercent: 50, yearToDateChangePercent: -10)
        let highYTD = InstrumentRow(instrument: novartis, price: 1, asOf: nil, dayChangePercent: nil, threeMonthChangePercent: nil, oneYearChangePercent: -20, yearToDateChangePercent: 30)
        let cache = InMemoryCache(initial: CachedSnapshot(rows: [highOneYear, highYTD], savedAt: Date()))
        let viewModel = MainViewModel(instruments: testInstruments, fetcher: ScriptedFetcher(scripts: [:]), cache: cache)
        viewModel.select(.switzerland)
        viewModel.toggleSort(.oneYear) // ascending by trailing 1Y

        #expect(viewModel.displayedRows.map(\.instrument.symbol) == ["NOVN.SW", "NESN.SW"])

        viewModel.toggleOneYearMode() // same ascending sort, now by YTD instead
        #expect(viewModel.displayedRows.map(\.instrument.symbol) == ["NESN.SW", "NOVN.SW"])
    }

    @Test func refreshPopulatesRowsAndUpdatesTimestamp() async {
        let fetcher = ScriptedFetcher(scripts: [
            "EURCHF=X": .success(points(0.94)),
            "USDCHF=X": .success(points(0.81)),
            "NESN.SW": .success(points(77.96)),
            "NOVN.SW": .success(points(100.0)),
        ])
        let viewModel = MainViewModel(instruments: testInstruments, fetcher: fetcher, cache: InMemoryCache())
        viewModel.select(.currencies)

        await viewModel.refresh()

        #expect(viewModel.isRefreshing == false)
        #expect(viewModel.progress == 1.0)
        #expect(viewModel.lastUpdated != nil)
        #expect(viewModel.failedFetches.isEmpty)
        #expect(viewModel.displayedRows.first { $0.instrument.symbol == "EURCHF=X" }?.price == 0.94)
    }

    @Test func refreshKeepsPreviousValueForSymbolThatFailsAfterRetries() async {
        let cachedRow = InstrumentRow(instrument: nestle, price: 77.96, asOf: Date(), dayChangePercent: 0.3, threeMonthChangePercent: -4.1, oneYearChangePercent: -12.8)
        let cache = InMemoryCache(initial: CachedSnapshot(rows: [cachedRow], savedAt: Date()))
        let fetcher = ScriptedFetcher(scripts: [
            "EURCHF=X": .success(points(0.94)),
            "USDCHF=X": .success(points(0.81)),
            "NESN.SW": .failure(.notFound),
            "NOVN.SW": .success(points(100.0)),
        ])
        let viewModel = MainViewModel(instruments: testInstruments, fetcher: fetcher, cache: cache)
        viewModel.select(.switzerland)

        await viewModel.refresh()

        #expect(viewModel.failedFetches.count == 1)
        // NESN.SW failed this refresh -> keeps its previously cached price rather than going blank.
        #expect(viewModel.displayedRows.first { $0.instrument.symbol == "NESN.SW" }?.price == 77.96)
        #expect(viewModel.displayedRows.first { $0.instrument.symbol == "NOVN.SW" }?.price == 100.0)
        // The UI needs to say *which* symbol failed, and why -- not just how many.
        #expect(viewModel.failedFetches.map(\.instrument.symbol) == ["NESN.SW"])
        #expect(viewModel.failedFetches.first?.reason == "Symbol nicht gefunden")
    }

    @Test func refreshStoresThePriceHistoryOfEachFetchedSymbol() async {
        let fetcher = ScriptedFetcher(scripts: [
            "EURCHF=X": .success(points(0.94)),
            "USDCHF=X": .success(points(0.81)),
            "NESN.SW": .success(points(77.96)),
            "NOVN.SW": .success(points(100.0)),
        ])
        let historyStore = InMemoryPriceHistoryStore()
        let viewModel = MainViewModel(instruments: testInstruments, fetcher: fetcher, cache: InMemoryCache(), priceHistoryStore: historyStore)

        await viewModel.refresh()

        #expect(historyStore.load(for: "NESN.SW")?.closes.map(\.close) == [77.96])
        #expect(historyStore.load(for: "EURCHF=X")?.closes.map(\.close) == [0.94])
        #expect(historyStore.load(for: "NESN.SW")?.fetchedAt == viewModel.lastUpdated)
    }

    @Test func refreshKeepsTheStoredPriceHistoryOfASymbolThatFails() async {
        let earlierHistory = PriceHistory(closes: points(70.0), fetchedAt: Date(timeIntervalSince1970: 1_700_000_000))
        let historyStore = InMemoryPriceHistoryStore()
        historyStore.save(earlierHistory, for: "NESN.SW")
        let fetcher = ScriptedFetcher(scripts: ["NESN.SW": .failure(.notFound)])
        let viewModel = MainViewModel(instruments: [nestle], fetcher: fetcher, cache: InMemoryCache(), priceHistoryStore: historyStore)

        await viewModel.refresh()

        #expect(historyStore.load(for: "NESN.SW") == earlierHistory)
    }

    @Test func priceHistoryReturnsTheStoredHistoryOfASymbol() {
        let storedHistory = PriceHistory(closes: points(77.96), fetchedAt: Date(timeIntervalSince1970: 1_700_000_000))
        let historyStore = InMemoryPriceHistoryStore()
        historyStore.save(storedHistory, for: "NESN.SW")
        let viewModel = MainViewModel(instruments: [nestle], fetcher: ScriptedFetcher(scripts: [:]), cache: InMemoryCache(), priceHistoryStore: historyStore)

        #expect(viewModel.priceHistory(for: "NESN.SW") == storedHistory)
        #expect(viewModel.priceHistory(for: "NOVN.SW") == nil)
    }

    @Test func chartViewModelShowsTheStoredHistoryOfTheInstrument() {
        let storedHistory = PriceHistory(closes: points(77.96), fetchedAt: Date())
        let historyStore = InMemoryPriceHistoryStore()
        historyStore.save(storedHistory, for: "NESN.SW")
        let viewModel = MainViewModel(instruments: [nestle], fetcher: ScriptedFetcher(scripts: [:]), cache: InMemoryCache(), priceHistoryStore: historyStore)

        let chart = viewModel.makeChartViewModel(for: nestle)

        #expect(chart.instrument == nestle)
        #expect(chart.points.map(\.close) == [77.96])
    }

    @Test func historyFetchedByTheChartIsStoredForTheNextOpen() async {
        let historyStore = InMemoryPriceHistoryStore()
        let chartFetcher = ScriptedFetcher(scripts: ["NESN.SW": .success(points(77.96))])
        let viewModel = MainViewModel(instruments: [nestle], fetcher: ScriptedFetcher(scripts: [:]), cache: InMemoryCache(), priceHistoryStore: historyStore, chartFetcher: chartFetcher)

        await viewModel.makeChartViewModel(for: nestle).load()

        #expect(historyStore.load(for: "NESN.SW")?.closes.map(\.close) == [77.96])
        #expect(viewModel.makeChartViewModel(for: nestle).points.map(\.close) == [77.96])
    }

    @Test func symbolFailingUnderTwoGroupsAppearsOnceInFailedFetches() async {
        // The same symbol can be listed in two groups (e.g. an index shown
        // both standalone and inside "Schweiz"); if it fails, it should
        // still only show up once -- not once per group membership.
        let sharedSymbol = Instrument(symbol: "^SSMI", name: "SMI", group: .switzerland)
        let sharedSymbolAgain = Instrument(symbol: "^SSMI", name: "SMI", group: .index)
        let fetcher = ScriptedFetcher(scripts: ["^SSMI": .failure(.notFound)])
        let viewModel = MainViewModel(instruments: [sharedSymbol, sharedSymbolAgain], fetcher: fetcher, cache: InMemoryCache())

        await viewModel.refresh()

        #expect(viewModel.failedFetches.map(\.instrument.symbol) == ["^SSMI"])
    }

    @Test func refreshSavesSnapshotToCache() async {
        let fetcher = ScriptedFetcher(scripts: [
            "EURCHF=X": .success(points(0.94)),
            "USDCHF=X": .success(points(0.81)),
            "NESN.SW": .success(points(77.96)),
            "NOVN.SW": .success(points(100.0)),
        ])
        let cache = InMemoryCache()
        let viewModel = MainViewModel(instruments: testInstruments, fetcher: fetcher, cache: cache)

        await viewModel.refresh()

        #expect(cache.load()?.rows.count == 4)
    }

    @Test func totalInstrumentCountReflectsFullList() {
        let viewModel = MainViewModel(instruments: testInstruments, fetcher: ScriptedFetcher(scripts: [:]), cache: InMemoryCache())
        #expect(viewModel.totalInstrumentCount == 4)
    }

    // MARK: - Range mode (1-month / 3-month column)

    @Test func rangeModeDefaultsToThreeMonthAndToggles() {
        let viewModel = MainViewModel(instruments: testInstruments, fetcher: ScriptedFetcher(scripts: [:]), cache: InMemoryCache())
        #expect(viewModel.rangeMode == .threeMonth)

        viewModel.toggleRangeMode()
        #expect(viewModel.rangeMode == .oneMonth)

        viewModel.toggleRangeMode()
        #expect(viewModel.rangeMode == .threeMonth)
    }

    @Test func togglingRangeModeReSortsWhenThreeMonthColumnIsActive() {
        let highThreeMonth = InstrumentRow(instrument: nestle, price: 1, asOf: nil, dayChangePercent: nil, threeMonthChangePercent: 50, oneYearChangePercent: nil, yearToDateChangePercent: nil, oneMonthChangePercent: -10)
        let highOneMonth = InstrumentRow(instrument: novartis, price: 1, asOf: nil, dayChangePercent: nil, threeMonthChangePercent: -20, oneYearChangePercent: nil, yearToDateChangePercent: nil, oneMonthChangePercent: 30)
        let cache = InMemoryCache(initial: CachedSnapshot(rows: [highThreeMonth, highOneMonth], savedAt: Date()))
        let viewModel = MainViewModel(instruments: testInstruments, fetcher: ScriptedFetcher(scripts: [:]), cache: cache)
        viewModel.select(.switzerland)
        viewModel.toggleSort(.threeMonth) // ascending by 3-month

        #expect(viewModel.displayedRows.map(\.instrument.symbol) == ["NOVN.SW", "NESN.SW"])

        viewModel.toggleRangeMode() // same ascending sort, now by 1-month instead
        #expect(viewModel.displayedRows.map(\.instrument.symbol) == ["NESN.SW", "NOVN.SW"])
    }

    // MARK: - Customizing lists

    @Test func addConstituentAppendsToGroupAndPersists() {
        let store = InMemoryConstituentsStore(initial: testInstruments)
        let viewModel = MainViewModel(instruments: testInstruments, fetcher: ScriptedFetcher(scripts: [:]), cache: InMemoryCache(), constituentsStore: store)

        viewModel.addConstituent(name: "Adecco", symbol: "ADEN.SW", to: .switzerland)

        #expect(viewModel.constituents(in: .switzerland).map(\.symbol).contains("ADEN.SW"))
        #expect(store.load()?.map(\.symbol).contains("ADEN.SW") == true)
    }

    @Test func addConstituentUpdatesDisplayedRowsWhenGroupIsSelected() {
        let viewModel = MainViewModel(instruments: testInstruments, fetcher: ScriptedFetcher(scripts: [:]), cache: InMemoryCache(), constituentsStore: InMemoryConstituentsStore(initial: testInstruments))
        viewModel.select(.switzerland)

        viewModel.addConstituent(name: "Adecco", symbol: "ADEN.SW", to: .switzerland)

        #expect(viewModel.displayedRows.map(\.instrument.symbol).contains("ADEN.SW"))
        #expect(viewModel.totalInstrumentCount == 5)
    }

    @Test func addConstituentWithBlankNameOrSymbolIsIgnored() {
        let viewModel = MainViewModel(instruments: testInstruments, fetcher: ScriptedFetcher(scripts: [:]), cache: InMemoryCache(), constituentsStore: InMemoryConstituentsStore(initial: testInstruments))

        viewModel.addConstituent(name: "  ", symbol: "ADEN.SW", to: .switzerland)
        viewModel.addConstituent(name: "Adecco", symbol: "  ", to: .switzerland)

        #expect(viewModel.constituents(in: .switzerland).map(\.symbol) == ["NESN.SW", "NOVN.SW"])
    }

    @Test func addConstituentAlreadyInGroupIsIgnored() {
        let viewModel = MainViewModel(instruments: testInstruments, fetcher: ScriptedFetcher(scripts: [:]), cache: InMemoryCache(), constituentsStore: InMemoryConstituentsStore(initial: testInstruments))

        viewModel.addConstituent(name: "Nestlé Again", symbol: "nesn.sw", to: .switzerland)

        #expect(viewModel.constituents(in: .switzerland).count == 2)
    }

    @Test func removeConstituentRemovesBundledInstrumentFromOnlyThatGroup() {
        let sharedSymbol = Instrument(symbol: "^SSMI", name: "SMI", group: .switzerland)
        let sharedSymbolAgain = Instrument(symbol: "^SSMI", name: "SMI", group: .index)
        let store = InMemoryConstituentsStore(initial: [sharedSymbol, sharedSymbolAgain])
        let viewModel = MainViewModel(instruments: [sharedSymbol, sharedSymbolAgain], fetcher: ScriptedFetcher(scripts: [:]), cache: InMemoryCache(), constituentsStore: store)

        viewModel.removeConstituent(symbol: "^SSMI", from: .switzerland)

        #expect(viewModel.constituents(in: .switzerland).isEmpty)
        #expect(viewModel.constituents(in: .index).map(\.symbol) == ["^SSMI"])
        #expect(store.load()?.count == 1)
    }

    @Test func removeConstituentUpdatesDisplayedRowsWhenGroupIsSelected() {
        let viewModel = MainViewModel(instruments: testInstruments, fetcher: ScriptedFetcher(scripts: [:]), cache: InMemoryCache(), constituentsStore: InMemoryConstituentsStore(initial: testInstruments))
        viewModel.select(.switzerland)

        viewModel.removeConstituent(symbol: "NESN.SW", from: .switzerland)

        #expect(!viewModel.displayedRows.map(\.instrument.symbol).contains("NESN.SW"))
        #expect(viewModel.totalInstrumentCount == 3)
    }

    @Test func persistedListFromDeviceIsUsedAtInitNotTheBundledOne() {
        // Simulates a device that already customized its list before this
        // launch: the store holds a list that differs from what's passed as
        // `instruments:` (the current build's bundled defaults). The stored
        // one must win -- that's the whole point.
        let onDeviceList = [Instrument(symbol: "ADEN.SW", name: "Adecco", group: .switzerland)]
        let store = InMemoryConstituentsStore(initial: onDeviceList)
        let viewModel = MainViewModel(instruments: testInstruments, fetcher: ScriptedFetcher(scripts: [:]), cache: InMemoryCache(), constituentsStore: store)

        #expect(viewModel.constituents(in: .switzerland).map(\.symbol) == ["ADEN.SW"])
        #expect(viewModel.totalInstrumentCount == 1)
    }

    @Test func freshInstallSeedsTheStoreFromBundledDefaults() {
        // No store contents yet (nil, not an empty array) -- simulates a
        // fresh install. The bundled defaults become the on-device list and
        // get persisted immediately, so this device now has its own copy
        // independent of future code changes to the bundled list.
        let store = InMemoryConstituentsStore()
        _ = MainViewModel(instruments: testInstruments, fetcher: ScriptedFetcher(scripts: [:]), cache: InMemoryCache(), constituentsStore: store)

        #expect(store.load()?.map(\.symbol) == testInstruments.map(\.symbol))
    }

    @Test func constituentsInGroupAreSortedAlphabeticallyByName() {
        // Declared in reverse-alphabetical order on purpose, so this only
        // passes if `constituents(in:)` actually sorts rather than just
        // preserving declaration order.
        let zurich = Instrument(symbol: "ZURN.SW", name: "Zurich Insurance", group: .switzerland)
        let adecco = Instrument(symbol: "ADEN.SW", name: "Adecco", group: .switzerland)
        let mitte = Instrument(symbol: "NESN.SW", name: "Nestlé", group: .switzerland)
        let viewModel = MainViewModel(instruments: [zurich, adecco, mitte], fetcher: ScriptedFetcher(scripts: [:]), cache: InMemoryCache())

        #expect(viewModel.constituents(in: .switzerland).map(\.name) == ["Adecco", "Nestlé", "Zurich Insurance"])
    }

    @Test func reAddingAConstituentRemovedEarlierMakesItPresentAgain() {
        let store = InMemoryConstituentsStore(initial: testInstruments)
        let viewModel = MainViewModel(instruments: testInstruments, fetcher: ScriptedFetcher(scripts: [:]), cache: InMemoryCache(), constituentsStore: store)

        viewModel.removeConstituent(symbol: "NESN.SW", from: .switzerland)
        #expect(!viewModel.constituents(in: .switzerland).map(\.symbol).contains("NESN.SW"))

        viewModel.addConstituent(name: "Nestlé", symbol: "NESN.SW", to: .switzerland)
        #expect(viewModel.constituents(in: .switzerland).map(\.symbol).contains("NESN.SW"))
    }

    @Test func resetConstituentsToDefaultsDiscardsCustomizationsAndPersists() {
        let store = InMemoryConstituentsStore(initial: testInstruments)
        let viewModel = MainViewModel(instruments: testInstruments, fetcher: ScriptedFetcher(scripts: [:]), cache: InMemoryCache(), constituentsStore: store)
        viewModel.addConstituent(name: "Adecco", symbol: "ADEN.SW", to: .switzerland)
        viewModel.removeConstituent(symbol: "NOVN.SW", from: .switzerland)
        #expect(viewModel.constituents(in: .switzerland).map(\.symbol) == ["ADEN.SW", "NESN.SW"])

        viewModel.resetConstituentsToDefaults()

        #expect(viewModel.constituents(in: .switzerland).map(\.symbol).sorted() == ["NESN.SW", "NOVN.SW"])
        #expect(store.load()?.map(\.symbol) == testInstruments.map(\.symbol))
    }

    @Test func resetConstituentsToDefaultsUpdatesDisplayedRowsForSelectedGroup() {
        let viewModel = MainViewModel(instruments: testInstruments, fetcher: ScriptedFetcher(scripts: [:]), cache: InMemoryCache(), constituentsStore: InMemoryConstituentsStore(initial: testInstruments))
        viewModel.select(.switzerland)
        viewModel.removeConstituent(symbol: "NESN.SW", from: .switzerland)
        #expect(!viewModel.displayedRows.map(\.instrument.symbol).contains("NESN.SW"))

        viewModel.resetConstituentsToDefaults()

        #expect(viewModel.displayedRows.map(\.instrument.symbol).contains("NESN.SW"))
    }
}
