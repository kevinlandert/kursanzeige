import Foundation

/// Abstraction over `Task.sleep` so retry backoff can be tested without
/// real waits.
protocol Sleeping: Sendable {
    func sleep(for seconds: TimeInterval) async throws
}

struct TaskSleeper: Sleeping {
    func sleep(for seconds: TimeInterval) async throws {
        try await Task.sleep(nanoseconds: UInt64(max(0, seconds) * 1_000_000_000))
    }
}
