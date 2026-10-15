import Testing
import Foundation
@testable import KursanzeigeKit

struct RetryPolicyTests {
    let policy = RetryPolicy(maxAttempts: 4)

    // MARK: - Which errors get retried

    @Test func retriesRateLimitedError() {
        #expect(policy.shouldRetry(afterAttempt: 1, error: .rateLimited(retryAfter: nil)))
    }

    @Test func retriesServerError() {
        #expect(policy.shouldRetry(afterAttempt: 1, error: .server(statusCode: 503)))
    }

    @Test func retriesNetworkError() {
        #expect(policy.shouldRetry(afterAttempt: 1, error: .network))
    }

    @Test func doesNotRetryNotFound() {
        #expect(!policy.shouldRetry(afterAttempt: 1, error: .notFound))
    }

    @Test func doesNotRetryDecodingError() {
        #expect(!policy.shouldRetry(afterAttempt: 1, error: .decoding))
    }

    @Test func stopsRetryingAfterMaxAttempts() {
        #expect(!policy.shouldRetry(afterAttempt: 4, error: .network))
        #expect(policy.shouldRetry(afterAttempt: 3, error: .network))
    }

    // MARK: - Backoff delay

    @Test func delayGrowsExponentiallyWithAttempt() {
        let d1 = policy.delay(forAttempt: 1, error: .network)
        let d2 = policy.delay(forAttempt: 2, error: .network)
        let d3 = policy.delay(forAttempt: 3, error: .network)
        // Base 1s, 2s, 4s plus jitter in [0, 0.5).
        #expect((1.0..<1.5).contains(d1))
        #expect((2.0..<2.5).contains(d2))
        #expect((4.0..<4.5).contains(d3))
    }

    @Test func rateLimitedRespectsRetryAfterWhenLonger() {
        let delay = policy.delay(forAttempt: 1, error: .rateLimited(retryAfter: 10))
        #expect(delay == 10)
    }

    @Test func rateLimitedUsesExponentialWhenRetryAfterIsShorter() {
        let delay = policy.delay(forAttempt: 3, error: .rateLimited(retryAfter: 1))
        #expect((4.0..<4.5).contains(delay))
    }

    @Test func rateLimitedFallsBackToExponentialWhenRetryAfterMissing() {
        let delay = policy.delay(forAttempt: 2, error: .rateLimited(retryAfter: nil))
        #expect((2.0..<2.5).contains(delay))
    }
}
