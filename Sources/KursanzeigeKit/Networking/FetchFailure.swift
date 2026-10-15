import Foundation

/// A single instrument's fetch failure, with the error that finally gave
/// up after retries -- not just the symbol. Internal: `MainViewModel`
/// translates this into the public, human-readable `FailedFetch`.
struct FetchFailure: Equatable {
    let symbol: String
    let error: FetchError
}

extension FetchError {
    /// Short German explanation shown next to a failed row so "3 von 53
    /// nicht geladen" stops being a mystery. Deliberately brief -- this
    /// sits in a list next to a large-font instrument name.
    var userFacingReason: String {
        switch self {
        case .notFound:
            return "Symbol nicht gefunden"
        case .rateLimited:
            return "Zu viele Anfragen (Rate-Limit)"
        case .server(let statusCode):
            return "Serverfehler (HTTP \(statusCode))"
        case .network:
            return "Netzwerkfehler"
        case .decoding:
            return "Antwort nicht lesbar"
        }
    }
}
