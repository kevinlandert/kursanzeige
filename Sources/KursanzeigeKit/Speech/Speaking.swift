/// Plays a text aloud. The app gives a speech synthesizer, a test gives
/// a recorder.
@MainActor
public protocol Speaking: AnyObject {
    /// Starts to read `text`.
    func speak(_ text: String)
    /// Stops the voice at once. Has no effect when the voice is silent.
    func stop()
}
