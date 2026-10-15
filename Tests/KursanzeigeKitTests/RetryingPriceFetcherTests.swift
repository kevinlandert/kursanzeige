import Testing
import Foundation
@testable import KursanzeigeKit

/// Instant no-op sleeper -- retry tests care about attempt counts and
/// delay values passed in, not wall-clock time.
private actor InstantSleeper: Sleeping {
    private(set) var requestedDelays: [TimeInterval] = []

    func sleep(for seconds: TimeInterval) async throws {
        requestedDelays.append(seconds)
    }
}

/// Fake fetcher that replays a scripted sequence of results per symbol,
/// one per call, and records how many times it was called.
private actor ScriptedFetcher: PriceFetching {
    private var scripts: [String: [Result<[ClosePoint], FetchError>]]
    private(set) var callCounts: [String: Int] = [:]

    init(scripts: [String: [Result<[ClosePoint], FetchError>]]) {
        self.scripts = scripts
    }

    func fetchCloses(for symbol: String) async throws -> [ClosePoint] {
        callCounts[symbol, default: 0] += 1
        guard var remaining = scripts[symbol], !remaining.isEmpty else {
            throw FetchError.network
        }
        let next = remaining.removeFirst()
        scripts[symbol] = remaining
        switch next {
        case .success(let points): return points
        case .failure(let error): throw error
        }
    }
}

struct RetryingPriceFetcherTests {

    @Test func succeedsWithoutRetryOnFirstTry() async throws {
        let points = [ClosePoint(date: Date(), close: 100)]
        let underlying = ScriptedFetcher(scripts: ["AAA": [.success(points)]])
        let sleeper = InstantSleeper()
        let fetcher = RetryingPriceFetcher(underlying: underlying, policy: RetryPolicy(maxAttempts: 4), sleeper: sleeper)

        let result = try await fetcher.fetchCloses(for: "AAA")

        #expect(result == points)
        #expect(await sleeper.requestedDelays.isEmpty)
        #expect(await underlying.callCounts["AAA"] == 1)
    }

    @Test func retriesOnRateLimitThenSucceeds() async throws {
        let points = [ClosePoint(date: Date(), close: 42)]
        let underlying = ScriptedFetcher(scripts: [
            "BBB": [.failure(.rateLimited(retryAfter: nil)), .failure(.rateLimited(retryAfter: nil)), .success(points)]
        ])
        let sleeper = InstantSleeper()
        let fetcher = RetryingPriceFetcher(underlying: underlying, policy: RetryPolicy(maxAttempts: 4), sleeper: sleeper)

        let result = try await fetcher.fetchCloses(for: "BBB")

        #expect(result == points)
        #expect(await underlying.callCounts["BBB"] == 3)
        #expect(await sleeper.requestedDelays.count == 2)
    }

    @Test func doesNotRetryNotFound() async throws {
        let underlying = ScriptedFetcher(scripts: ["CCC": [.failure(.notFound)]])
        let sleeper = InstantSleeper()
        let fetcher = RetryingPriceFetcher(underlying: underlying, policy: RetryPolicy(maxAttempts: 4), sleeper: sleeper)

        await #expect(throws: FetchError.notFound) {
            _ = try await fetcher.fetchCloses(for: "CCC")
        }
        #expect(await underlying.callCounts["CCC"] == 1)
        #expect(await sleeper.requestedDelays.isEmpty)
    }

    @Test func givesUpAfterMaxAttemptsAndThrowsLastError() async throws {
        let underlying = ScriptedFetcher(scripts: [
            "DDD": [.failure(.network), .failure(.network), .failure(.network), .failure(.network)]
        ])
        let sleeper = InstantSleeper()
        let fetcher = RetryingPriceFetcher(underlying: underlying, policy: RetryPolicy(maxAttempts: 4), sleeper: sleeper)

        await #expect(throws: FetchError.network) {
            _ = try await fetcher.fetchCloses(for: "DDD")
        }
        #expect(await underlying.callCounts["DDD"] == 4)
        // Retries happen after attempts 1, 2, 3 (not after the final, exhausted attempt).
        #expect(await sleeper.requestedDelays.count == 3)
    }
}
