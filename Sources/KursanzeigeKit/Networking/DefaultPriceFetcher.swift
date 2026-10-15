import Foundation

/// Assembles the production fetcher: real Yahoo Finance requests wrapped
/// with retry-and-backoff. Kept as a single factory so `MainViewModel`'s
/// public API doesn't need to expose `YahooFinanceClient` or `RetryPolicy`
/// as public types -- callers outside the package just get `MainViewModel()`.
enum DefaultPriceFetcher {
    static func make() -> PriceFetching {
        RetryingPriceFetcher(underlying: YahooFinanceClient(), policy: RetryPolicy(maxAttempts: 4))
    }
}
