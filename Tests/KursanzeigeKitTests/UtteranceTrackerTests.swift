import Testing
@testable import KursanzeigeKit

@Suite("UtteranceTracker")
@MainActor
struct UtteranceTrackerTests {
    /// Starts a speech in its own task and gives the utterance id that
    /// the tracker gave to the synthesizer.
    private func startSpeech(_ tracker: UtteranceTracker) async -> (Task<Bool, Never>, Int) {
        var startedId: Int?
        let speech = Task { await tracker.speak { startedId = $0 } }
        await waitUntil { startedId != nil }
        return (speech, startedId ?? 0)
    }

    @Test("a finished utterance ends the speech with true")
    func finishedUtteranceEndsWithTrue() async {
        let tracker = UtteranceTracker()
        let (speech, utteranceId) = await startSpeech(tracker)
        #expect(tracker.isSpeaking)

        tracker.finishUtterance(id: utteranceId)

        #expect(await speech.value)
        #expect(tracker.isSpeaking == false)
    }

    @Test("a cancelled utterance ends the speech with false")
    func cancelledUtteranceEndsWithFalse() async {
        let tracker = UtteranceTracker()
        let (speech, utteranceId) = await startSpeech(tracker)

        tracker.cancelUtterance(id: utteranceId)

        #expect(await speech.value == false)
    }

    @Test("a stop ends the speech with false at once")
    func stopEndsWithFalse() async {
        let tracker = UtteranceTracker()
        let (speech, _) = await startSpeech(tracker)

        tracker.cancelSpeech()

        #expect(await speech.value == false)
    }

    @Test("a late callback of a stopped speech does not end the next speech")
    func lateCallbackDoesNotEndNextSpeech() async {
        let tracker = UtteranceTracker()
        let (firstSpeech, firstId) = await startSpeech(tracker)
        tracker.cancelSpeech()
        _ = await firstSpeech.value
        let (secondSpeech, secondId) = await startSpeech(tracker)

        tracker.finishUtterance(id: firstId)
        #expect(tracker.isSpeaking)

        tracker.finishUtterance(id: secondId)
        #expect(await secondSpeech.value)
        #expect(firstId != secondId)
    }

    @Test("a new speech ends the waiting speech with false")
    func newSpeechEndsWaitingSpeech() async {
        let tracker = UtteranceTracker()
        let (firstSpeech, _) = await startSpeech(tracker)

        let (_, secondId) = await startSpeech(tracker)

        #expect(await firstSpeech.value == false)
        tracker.finishUtterance(id: secondId)
    }
}
