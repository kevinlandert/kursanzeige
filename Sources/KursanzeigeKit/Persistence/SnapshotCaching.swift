import Foundation

/// Persists the last successful refresh across launches. Kept as a
/// protocol so `MainViewModel` can be tested with an in-memory fake instead
/// of touching disk.
protocol SnapshotCaching: Sendable {
    func load() -> CachedSnapshot?
    func save(_ snapshot: CachedSnapshot)
}
