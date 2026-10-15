import Foundation

/// Persists the on-device working list of constituents across launches --
/// the full list for every group, not a delta against the bundled
/// defaults. That's deliberate: once a device has its own copy, a future
/// app update changing `constituents.json` (a renamed ticker, a new
/// default, a dropped one) must not silently reshuffle what's already on
/// screen. `load()` returning `nil` means "nothing saved yet" (a fresh
/// install, or a device that has never customized anything), distinct from
/// an actual saved empty list -- `MainViewModel` uses that to know when to
/// seed the store from the bundled defaults.
protocol ConstituentsStoring: Sendable {
    func load() -> [Instrument]?
    func save(_ instruments: [Instrument])
}

/// Default for call sites (most existing `MainViewModel` tests) that don't
/// exercise list customization at all -- always empty, never persists.
struct NoOpConstituentsStore: ConstituentsStoring {
    func load() -> [Instrument]? { nil }
    func save(_ instruments: [Instrument]) {}
}
