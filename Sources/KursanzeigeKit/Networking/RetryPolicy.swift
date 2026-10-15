import Foundation

/// Decides whether a failed fetch attempt should be retried, and how long
/// to wait before the next try. Pure and deterministic apart from jitter,
/// so it can be unit tested without a network stack.
struct RetryPolicy: Sendable {
    let maxAttempts: Int
    /// Injectable so tests can pin jitter; defaults to a small random offset
    /// that spreads out retries when many symbols fail at once (avoids
    /// every request retrying in the exact same instant).
    var jitter: @Sendable () -> TimeInterval = { Double.random(in: 0..<0.5) }

    /// `attempt` is 1-based: the attempt that just failed.
    func shouldRetry(afterAttempt attempt: Int, error: FetchError) -> Bool {
        attempt < maxAttempts && error.isRetryable
    }

    /// Delay before the next attempt (`attempt` is the one that just failed).
    /// Exponential backoff (1s, 2s, 4s, ...) plus jitter, except a rate-limit
    /// response's `Retry-After` overrides the backoff when it asks for longer.
    func delay(forAttempt attempt: Int, error: FetchError) -> TimeInterval {
        let exponential = pow(2.0, Double(attempt - 1)) + jitter()
        if case .rateLimited(let retryAfter?) = error {
            return max(retryAfter, exponential)
        }
        return exponential
    }
}
