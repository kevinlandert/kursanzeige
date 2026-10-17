import Foundation
import Observation

/// Drives the single-screen table: which group is selected, its current
/// sort, and the refresh lifecycle (progress, partial-failure handling,
/// and caching). This is the only public type views talk to -- the
/// networking, retry, and persistence types behind it stay internal to
/// the package.
@Observable
@MainActor
public final class MainViewModel {
    public private(set) var selectedGroup: MarketGroup
    public private(set) var displayedRows: [InstrumentRow] = []
    public private(set) var sortColumn: SortColumn = .name
    public private(set) var sortAscending: Bool = true
    /// Whether the rightmost column shows trailing 12 months or
    /// year-to-date. One app-wide toggle, not per-row.
    public private(set) var oneYearMode: OneYearMode = .trailing
    /// Whether the 3-Monate column shows the trailing 1 month or 3 months.
    /// One app-wide toggle, not per-row.
    public private(set) var rangeMode: RangeMode = .threeMonth
    public private(set) var isRefreshing: Bool = false
    public private(set) var progress: Double = 0
    public private(set) var lastUpdated: Date?
    /// The instruments that failed on the last refresh, with a short reason
    /// each, so the UI can show exactly which ones -- and why -- rather
    /// than just a count.
    public private(set) var failedFetches: [FailedFetch] = []
    public var totalInstrumentCount: Int { instruments.count }

    /// The list bundled with this build of the app, exactly as passed in at
    /// init -- never mutated after that. Used only as the seed for a fresh
    /// install and as the target of `resetConstituentsToDefaults()`; it is
    /// NOT what's shown day to day (see `instruments` below).
    private let defaultInstruments: [Instrument]
    private let constituentsStore: ConstituentsStoring
    /// The actual working list, for every group. Loaded from
    /// `constituentsStore` at init if a device copy already exists;
    /// otherwise seeded from `defaultInstruments` and persisted immediately.
    /// From then on this is fully independent of `defaultInstruments` -- an
    /// app update alone never changes it, only an explicit add, remove, or
    /// reset does, each of which re-persists it.
    private var instruments: [Instrument]
    private let coordinator: RefreshCoordinator
    private let cache: SnapshotCaching
    private let priceHistoryStore: PriceHistoryStoring
    /// Fetches a chart's history when none is stored. Separate from the
    /// refresh fetcher, because it gives up sooner (see `ChartPriceFetcher`).
    private let chartFetcher: PriceFetching
    /// The initial `sortColumn`/`sortAscending` are just a default display
    /// order, not the result of a tap. Without this flag, the first tap on
    /// the already-displayed default column would look like a *second* tap
    /// and flip to descending instead of confirming ascending.
    private var hasExplicitSort = false
    /// Latest known row per symbol, from cache and/or successful fetches.
    /// A symbol missing here (never cached, never fetched) falls back to
    /// `InstrumentRow.empty`.
    private var knownRows: [String: InstrumentRow] = [:]

    /// Full dependency injection, used by tests and by the public
    /// convenience init below. Not public itself so `PriceFetching` and
    /// `SnapshotCaching` don't need to be part of the package's public API.
    init(
        instruments: [Instrument],
        fetcher: PriceFetching,
        cache: SnapshotCaching,
        maxConcurrency: Int = 4,
        calendar: Calendar = .current,
        constituentsStore: ConstituentsStoring = NoOpConstituentsStore(),
        priceHistoryStore: PriceHistoryStoring = NoOpPriceHistoryStore(),
        chartFetcher: PriceFetching? = nil
    ) {
        self.defaultInstruments = instruments
        self.constituentsStore = constituentsStore
        if let onDevice = constituentsStore.load() {
            self.instruments = onDevice
        } else {
            self.instruments = instruments
            constituentsStore.save(instruments)
        }
        self.coordinator = RefreshCoordinator(fetcher: fetcher, maxConcurrency: maxConcurrency, calendar: calendar)
        self.cache = cache
        self.priceHistoryStore = priceHistoryStore
        self.chartFetcher = chartFetcher ?? fetcher
        self.selectedGroup = instruments.first?.group ?? MarketGroup.allCases[0]

        if let snapshot = cache.load() {
            for row in snapshot.rows {
                knownRows[row.instrument.symbol] = row
            }
            lastUpdated = snapshot.savedAt
        }
        applyRowsForSelectedGroup()
    }

    /// Production entry point: bundled constituents, real Yahoo Finance
    /// fetching with retry, on-disk cache and price histories. Everything a
    /// view needs is `MainViewModel()`.
    public convenience init() {
        self.init(
            instruments: (try? Constituents.load()) ?? [],
            fetcher: DefaultPriceFetcher.make(),
            cache: FileSnapshotCache(),
            constituentsStore: FileConstituentsStore(),
            priceHistoryStore: FilePriceHistoryStore(),
            chartFetcher: ChartPriceFetcher.make()
        )
    }

    public func select(_ group: MarketGroup) {
        guard group != selectedGroup else { return }
        selectedGroup = group
        applyRowsForSelectedGroup()
    }

    /// Tapping the header of the already-sorted column reverses direction;
    /// tapping a different header sorts by it ascending.
    public func toggleSort(_ column: SortColumn) {
        if hasExplicitSort && column == sortColumn {
            sortAscending.toggle()
        } else {
            sortColumn = column
            sortAscending = true
        }
        hasExplicitSort = true
        applyRowsForSelectedGroup()
    }

    /// Switches the rightmost column between trailing 12 months and
    /// year-to-date, re-sorting immediately if that column is the active
    /// sort so the displayed order never contradicts what's on screen.
    public func toggleOneYearMode() {
        oneYearMode = oneYearMode == .trailing ? .yearToDate : .trailing
        applyRowsForSelectedGroup()
    }

    /// Switches the 3-Monate column between trailing 1 month and 3 months,
    /// re-sorting immediately if that column is the active sort -- same
    /// rationale as `toggleOneYearMode`.
    public func toggleRangeMode() {
        rangeMode = rangeMode == .threeMonth ? .oneMonth : .threeMonth
        applyRowsForSelectedGroup()
    }

    /// The constituents currently configured for a group (bundled defaults
    /// plus any the user added, minus any they removed), alphabetical by
    /// name -- for the settings list editor. Not filtered by selection --
    /// unlike `displayedRows`, this needs to show any group regardless of
    /// which one is on screen.
    public func constituents(in group: MarketGroup) -> [Instrument] {
        instruments
            .filter { $0.group == group }
            .sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
    }

    /// Adds a user-defined constituent to a group. Ignored if the name or
    /// symbol is blank, if the symbol contains anything outside the
    /// character range a real ticker uses (letters, digits, "-.^=" --
    /// see `Instrument.isValidSymbol`), or if that symbol is already in
    /// the group (adding a duplicate would produce two identically-keyed
    /// rows in the table).
    public func addConstituent(name: String, symbol: String, to group: MarketGroup) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSymbol = symbol.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !trimmedName.isEmpty, Instrument.isValidSymbol(trimmedSymbol) else { return }
        guard !instruments.contains(where: { $0.group == group && $0.symbol.uppercased() == trimmedSymbol }) else { return }

        instruments.append(Instrument(symbol: trimmedSymbol, name: trimmedName, group: group))
        constituentsStore.save(instruments)

        if selectedGroup == group { applyRowsForSelectedGroup() }
    }

    /// Removes a constituent from one group, whether it's a bundled default
    /// or something the user added. Scoped to this group only -- the same
    /// symbol elsewhere (e.g. an index also shown standalone) is unaffected.
    public func removeConstituent(symbol: String, from group: MarketGroup) {
        instruments.removeAll { $0.symbol == symbol && $0.group == group }
        constituentsStore.save(instruments)

        if selectedGroup == group { applyRowsForSelectedGroup() }
    }

    /// Restores every group's constituents to the list bundled with this
    /// build of the app, discarding all on-device additions and removals.
    /// This is the only way the bundled defaults ever take effect again
    /// after first launch -- an app update alone never does (see
    /// `instruments`), so a code change to the default list can't silently
    /// reshuffle what someone customized.
    public func resetConstituentsToDefaults() {
        instruments = defaultInstruments
        constituentsStore.save(instruments)
        applyRowsForSelectedGroup()
    }

    /// The closes stored by the last refresh that fetched `symbol`, for the
    /// chart. `nil` if no refresh has fetched it yet.
    func priceHistory(for symbol: String) -> PriceHistory? {
        priceHistoryStore.load(for: symbol)
    }

    /// The chart of one instrument, with its stored history. Call it once
    /// per row tap: it reads the history file. A history that the chart
    /// must fetch is stored, so the next open needs no network. `range`
    /// lets "Nächste" and "Vorherige" keep the range of the last chart.
    public func makeChartViewModel(for instrument: Instrument, range: ChartRange = .oneYear) -> InstrumentChartViewModel {
        InstrumentChartViewModel(
            instrument: instrument,
            range: range,
            storedHistory: priceHistory(for: instrument.symbol),
            fetcher: chartFetcher,
            onFetched: { [weak self] history in
                await self?.save([instrument.symbol: history])
            }
        )
    }

    /// Fetches fresh data for every instrument (selected group first, so it
    /// fills in fastest), then the rest. A symbol that still fails after
    /// retries keeps whatever value and price history it last had -- fresh
    /// data never replaces good data with a blank.
    public func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        progress = 0
        defer { isRefreshing = false }

        let inSelectedGroup = instruments.filter { $0.group == selectedGroup }
        let others = instruments.filter { $0.group != selectedGroup }
        let orderedInstruments = inSelectedGroup + others

        let referenceDate = Date()
        let result = await coordinator.refresh(orderedInstruments, asOf: referenceDate) { [weak self] fraction in
            Task { @MainActor in
                self?.progress = fraction
            }
        }

        for row in result.rows {
            knownRows[row.instrument.symbol] = row
        }
        // A symbol shared across groups (e.g. the SMI index is both
        // "Schweiz" and "Index") is fetched once per group membership and
        // could fail more than once; de-duplicated here by symbol so it
        // shows up once in the list, not as a repeated (and duplicate-ID)
        // row.
        let instrumentsBySymbol = Dictionary(orderedInstruments.map { ($0.symbol, $0) }, uniquingKeysWith: { first, _ in first })
        var seenSymbols = Set<String>()
        failedFetches = result.failures.compactMap { failure -> FailedFetch? in
            guard seenSymbols.insert(failure.symbol).inserted else { return nil }
            guard let instrument = instrumentsBySymbol[failure.symbol] else { return nil }
            return FailedFetch(instrument: instrument, reason: failure.error.userFacingReason)
        }
        lastUpdated = referenceDate
        applyRowsForSelectedGroup()

        cache.save(CachedSnapshot(rows: Array(knownRows.values), savedAt: referenceDate))
        await save(result.histories)
    }

    /// Writes the histories off the main actor: five years of closes for
    /// every symbol is a few MB of JSON, and encoding it on the main actor
    /// would freeze the UI at the end of each refresh.
    private func save(_ histories: [String: PriceHistory]) async {
        let store = priceHistoryStore
        await Task.detached(priority: .utility) {
            for (symbol, history) in histories {
                store.save(history, for: symbol)
            }
        }.value
    }

    private func applyRowsForSelectedGroup() {
        let rows = instruments
            .filter { $0.group == selectedGroup }
            .map { knownRows[$0.symbol] ?? .empty($0) }
        displayedRows = InstrumentSorter.sort(rows, by: SortState(column: sortColumn, ascending: sortAscending), oneYearMode: oneYearMode, rangeMode: rangeMode)
    }
}
