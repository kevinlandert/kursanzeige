import Foundation

/// Keeps the last fetched `PriceHistory` of each symbol across launches,
/// so the chart opens without a network. A protocol, so `MainViewModel`
/// can be tested with an in-memory fake instead of the disk.
protocol PriceHistoryStoring: Sendable {
    func load(for symbol: String) -> PriceHistory?
    func save(_ history: PriceHistory, for symbol: String)
}

/// Default for `MainViewModel` tests that do not test price histories.
/// It stores nothing.
struct NoOpPriceHistoryStore: PriceHistoryStoring {
    func load(for symbol: String) -> PriceHistory? { nil }
    func save(_ history: PriceHistory, for symbol: String) {}
}
