import Foundation

/// An instrument that failed to load on the last refresh, with a short
/// human-readable reason -- so "3 von 53 nicht geladen" can be expanded
/// into specifics without the view needing to know about `FetchError` or
/// any other networking type.
public struct FailedFetch: Identifiable, Sendable, Equatable {
    public let instrument: Instrument
    public let reason: String

    public var id: String { instrument.symbol }

    public init(instrument: Instrument, reason: String) {
        self.instrument = instrument
        self.reason = reason
    }
}
