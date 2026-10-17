/// Plays a text aloud. The app gives a speech synthesizer, a test gives
/// a recorder.
@MainActor
public protocol Speaking: AnyObject {
    /// Reads `text` and waits until the voice ends it.
    /// - Returns: true only when the voice read the text to the end. False
    ///   after `stop()`, or when iOS stopped the voice.
    func speak(_ text: String) async -> Bool
    /// Stops the voice at once. Has no effect when the voice is silent.
    func stop()
}
