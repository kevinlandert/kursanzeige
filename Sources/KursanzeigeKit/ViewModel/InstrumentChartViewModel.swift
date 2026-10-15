import Foundation
import Observation

/// Drives the full-screen chart for a single instrument. It shows the price
/// history that "Aktualisieren" stored, and cuts each range from it, so
/// the chart opens at once, also offline, and agrees with the table. It
/// fetches only when no history is stored for the symbol yet.
/// `MainViewModel.makeChartViewModel(for:)` creates it, once per row tap.
@Observable
@MainActor
public final class InstrumentChartViewModel: Identifiable {
    /// The instrument of the tapped row: its name for the title, its group
    /// for the price format.
    public let instrument: Instrument
    /// The shown period. Starts on one year, unless the caller gives one.
    public private(set) var range: ChartRange
    /// True while `load()` fetches a history that was not stored.
    public private(set) var isLoading = false
    /// A German reason for the last failed fetch. `nil` after a success.
    public private(set) var errorMessage: String?

    /// A long line has at most this many points: more make the thick line
    /// a scribble of daily moves (see `LineThinner`).
    static let maximumPointCount = 75

    /// The closes of `range`, sorted oldest to newest. A long range is
    /// thinned, but keeps its first, last, highest and lowest close.
    /// Stored, because the view reads it many times per render.
    public private(set) var points: [ClosePoint] = []
    /// The lowest close in `points`, for the low label on the axis.
    public var minClose: Double? { points.map(\.close).min() }
    /// The highest close in `points`, for the high label on the axis.
    public var maxClose: Double? { points.map(\.close).max() }
    /// The change from the first to the last shown close, in percent. The
    /// first close is the base close of the range, so this equals the
    /// table's change for that period. `nil` without closes.
    public var rangeChangePercent: Double? {
        guard let first = points.first?.close, let last = points.last?.close, first != 0 else { return nil }
        return (last - first) / first * 100
    }
    /// The symbol, so `fullScreenCover(item:)` can present the chart.
    public nonisolated var id: String { instrument.symbol }

    private var history: PriceHistory?
    private let fetcher: PriceFetching
    private let calendar: Calendar
    private let now: () -> Date
    /// Receives a history that `load()` fetched, so the caller can store it
    /// and the next open of this chart needs no network.
    private let onFetched: (PriceHistory) async -> Void

    init(
        instrument: Instrument,
        range: ChartRange = .oneYear,
        storedHistory: PriceHistory?,
        fetcher: PriceFetching,
        calendar: Calendar = .current,
        now: @escaping () -> Date = Date.init,
        onFetched: @escaping (PriceHistory) async -> Void = { _ in }
    ) {
        self.instrument = instrument
        self.range = range
        self.history = storedHistory
        self.fetcher = fetcher
        self.calendar = calendar
        self.now = now
        self.onFetched = onFetched
        self.points = makePoints()
    }

    /// Shows `range`, cut from the history that is already in memory.
    /// No fetch.
    public func select(_ range: ChartRange) {
        self.range = range
        points = makePoints()
    }

    /// The text that "Vorlesen" reads for this chart, e.g. "Nestlé, 1 Jahr,
    /// 77,96, plus 3,2 Prozent". `rangeName` is the label of the range
    /// button, so the voice and the screen use the same words. `nil`
    /// without closes.
    public func spokenSummary(rangeName: String) -> String? {
        guard let lastClose = points.last?.close else { return nil }
        return ChartSpeech.text(
            name: instrument.name,
            rangeName: rangeName,
            price: lastClose,
            group: instrument.group,
            changePercent: rangeChangePercent
        )
    }

    /// Fetches the history only when none is stored. Ignored while a fetch
    /// is in flight, so a second call cannot start a parallel request.
    public func load() async {
        guard history == nil, !isLoading else { return }
        isLoading = true
        errorMessage = nil

        do {
            let fetched = PriceHistory(closes: try await fetcher.fetchCloses(for: instrument.symbol), fetchedAt: now())
            history = fetched
            points = makePoints()
            await onFetched(fetched)
        } catch let error as FetchError {
            errorMessage = error.userFacingReason
        } catch {
            errorMessage = "Unbekannter Fehler"
        }
        isLoading = false
    }

    private func makePoints() -> [ClosePoint] {
        guard let history else { return [] }
        return LineThinner.thin(history.closes(in: range, calendar: calendar), toAtMost: Self.maximumPointCount)
    }
}
