import Foundation

/// The last successful refresh, persisted so the app can open showing real
/// data (with an honest "as of" time) even before the user taps
/// "Aktualisieren" again, or with no network available at all.
struct CachedSnapshot: Codable, Equatable {
    let rows: [InstrumentRow]
    let savedAt: Date
}
