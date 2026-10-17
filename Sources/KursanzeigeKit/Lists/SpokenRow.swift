/// One row of a list for the reader: its id for the cursor store, its
/// title for the lock screen and its text for the voice.
struct SpokenRow {
    let id: String
    /// The name of the instrument.
    let title: String
    /// Gives the text that the voice reads. It can wait, for example for
    /// a chart history that is not loaded yet.
    let speech: @MainActor () async -> String
}
