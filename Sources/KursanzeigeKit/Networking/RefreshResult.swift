import Foundation

/// Outcome of refreshing a batch of instruments. `rows` holds only the
/// instruments that fetched successfully; the caller (the view model) is
/// responsible for falling back to previously cached data for anything
/// listed in `failures`, so a flaky refresh never blanks out a row that
/// briefly failed to update.
struct RefreshResult: Equatable {
    let rows: [InstrumentRow]
    /// The fetched closes of each successful instrument, by symbol.
    let histories: [String: PriceHistory]
    let failures: [FetchFailure]
}
