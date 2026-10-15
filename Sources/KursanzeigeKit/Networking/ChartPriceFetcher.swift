import Foundation

/// Assembles the fetcher the chart overlay uses when no price history is
/// stored for its symbol yet: an instrument added after the last
/// "Aktualisieren", or one whose last fetch failed. The person waits in
/// front of a spinner, so it gives up sooner than `DefaultPriceFetcher`:
/// a shorter timeout and fewer attempts.
enum ChartPriceFetcher {
    static func make() -> PriceFetching {
        RetryingPriceFetcher(underlying: YahooFinanceClient(requestTimeout: 10), policy: RetryPolicy(maxAttempts: 2))
    }
}
