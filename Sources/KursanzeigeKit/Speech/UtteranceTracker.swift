/// Records the utterance of the current text that did not end, and ends
/// the wait of the speaker. The speaker of the app gives the callbacks of
/// the speech synthesizer to it. The logic is in the package, so that it
/// has tests on the Mac.
///
/// - The speech ends with true when the synthesizer finished the utterance.
/// - It ends with false at once at a stop. The synthesizer can skip the
///   cancel callback for an utterance that did not start, so the stop
///   cannot wait for it.
/// - Each utterance has a new id. Thus a late callback of a stopped text
///   does not end the next text, and no wait ends two times.
@MainActor
public final class UtteranceTracker {
    private var nextUtteranceId = 1
    private var currentSpeech: TrackedSpeech?

    public init() {}

    /// True while a text waits for its utterance.
    public var isSpeaking: Bool {
        currentSpeech != nil
    }

    /// Gives a new utterance id to `start` and waits until the text ends.
    /// A text that still waits ends with false first. The caller must stop
    /// the synthesizer before, else the old utterance plays first.
    ///
    /// - Parameter start: gives the utterance to the synthesizer. It runs
    ///   before the first suspension, so a stop after this call always
    ///   stops this utterance.
    /// - Returns: true when the synthesizer finished the utterance.
    public func speak(start: (Int) -> Void) async -> Bool {
        cancelSpeech()
        let utteranceId = nextUtteranceId
        nextUtteranceId += 1
        return await withCheckedContinuation { continuation in
            currentSpeech = TrackedSpeech(utteranceId: utteranceId, continuation: continuation)
            start(utteranceId)
        }
    }

    /// The synthesizer read the utterance to the end. An unknown id
    /// changes nothing.
    public func finishUtterance(id: Int) {
        guard currentSpeech?.utteranceId == id else { return }
        endSpeech(isFinished: true)
    }

    /// The synthesizer cancelled the utterance, for example after an audio
    /// interruption. An unknown id changes nothing.
    public func cancelUtterance(id: Int) {
        guard currentSpeech?.utteranceId == id else { return }
        endSpeech(isFinished: false)
    }

    /// Ends the waiting text with false. Call it when the speaker stops.
    /// Has no effect without a text.
    public func cancelSpeech() {
        endSpeech(isFinished: false)
    }

    /// Removes the text before the resume, so that no wait ends two times.
    private func endSpeech(isFinished: Bool) {
        guard let speech = currentSpeech else { return }
        currentSpeech = nil
        speech.continuation.resume(returning: isFinished)
    }
}

/// The utterance of the current text and its wait.
private struct TrackedSpeech {
    let utteranceId: Int
    let continuation: CheckedContinuation<Bool, Never>
}
