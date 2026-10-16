import Foundation

/// Fetches the raw daily-close history for one symbol, with its unit.
/// Kept separate from percent-change calculation so the network layer can
/// be swapped or faked in tests without touching `PerformanceCalculator`.
protocol PriceFetching: Sendable {
    func fetchCloses(for symbol: String) async throws -> FetchedCloses
}
