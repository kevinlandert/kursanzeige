import Foundation

/// Wraps any `PriceFetching` with retry-with-backoff, per `RetryPolicy`.
/// Errors other than `FetchError` (a programming mistake, not a fetch
/// failure) are not retried and propagate immediately.
struct RetryingPriceFetcher: PriceFetching {
    let underlying: PriceFetching
    let policy: RetryPolicy
    let sleeper: Sleeping

    init(underlying: PriceFetching, policy: RetryPolicy, sleeper: Sleeping = TaskSleeper()) {
        self.underlying = underlying
        self.policy = policy
        self.sleeper = sleeper
    }

    func fetchCloses(for symbol: String) async throws -> [ClosePoint] {
        var attempt = 1
        while true {
            do {
                return try await underlying.fetchCloses(for: symbol)
            } catch let error as FetchError {
                guard policy.shouldRetry(afterAttempt: attempt, error: error) else { throw error }
                try await sleeper.sleep(for: policy.delay(forAttempt: attempt, error: error))
                attempt += 1
            }
        }
    }
}
