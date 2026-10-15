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
    /// The shown period. Starts on one year.
    public private(set) var range: ChartRange
    /// True while `load()` fetches a history that was not stored.
    public private(set) var isLoading = false
    /// A German reason for the last failed fetch. `nil` after a success.
    public private(set) var errorMessage: String?

    /// Sorted oldest to newest, and only the closes of `range`.
    public var points: [ClosePoint] { history?.closes(in: range, calendar: calendar) ?? [] }
    /// The lowest close in `points`, for the low label on the axis.
    public var minClose: Double? { points.map(\.close).min() }
    /// The highest close in `points`, for the high label on the axis.
    public var maxClose: Double? { points.map(\.close).max() }
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
        storedHistory: PriceHistory?,
        fetcher: PriceFetching,
        calendar: Calendar = .current,
        now: @escaping () -> Date = Date.init,
        onFetched: @escaping (PriceHistory) async -> Void = { _ in }
    ) {
        self.instrument = instrument
        self.range = .oneYear
        self.history = storedHistory
        self.fetcher = fetcher
        self.calendar = calendar
        self.now = now
        self.onFetched = onFetched
    }

    /// Shows `range`, cut from the history that is already in memory.
    /// No fetch.
    public func select(_ range: ChartRange) {
        self.range = range
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
            await onFetched(fetched)
        } catch let error as FetchError {
            errorMessage = error.userFacingReason
        } catch {
            errorMessage = "Unbekannter Fehler"
        }
        isLoading = false
    }
}
