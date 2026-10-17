import AVFoundation
import KursanzeigeKit
import os

/// `Speaking` with the iOS speech synthesizer and a German voice. The
/// voice plays as spoken audio, so it is audible also in silent mode and
/// with a locked screen. While it reads, other audio stops, so that the
/// AirPods and the lock screen control the app.
///
/// `SpeechEngine` does the work with the synthesizer. `UtteranceTracker`
/// tells when the text ended, and has tests in the package. `AppModel`
/// makes one speaker for the full app life, and both pages share it.
@MainActor
final class SynthesizerSpeaker: Speaking {
    private let tracker: UtteranceTracker
    private let engine: SpeechEngine
    private let findSpeechRate: @MainActor () -> SpeechRate

    /// - Parameter findSpeechRate: gives the „Sprechtempo“ of the settings
    ///   at the start of each text.
    init(findSpeechRate: @escaping @MainActor () -> SpeechRate) {
        self.findSpeechRate = findSpeechRate
        let tracker = UtteranceTracker()
        self.tracker = tracker
        // The callbacks come in separate tasks. The tracker accepts them in any order.
        self.engine = SpeechEngine { utteranceId, end in
            Task { @MainActor in
                switch end {
                case .finished: tracker.finishUtterance(id: utteranceId)
                case .cancelled: tracker.cancelUtterance(id: utteranceId)
                }
            }
        }
    }

    /// The engine gets the text before the first suspension. Its queue
    /// keeps the order, so a `stop()` after this call stops this text.
    func speak(_ text: String) async -> Bool {
        if tracker.isSpeaking {
            stop()
        }
        let rateFactor = findSpeechRate().factor
        let isFinished = await tracker.speak { utteranceId in
            engine.speak(text, utteranceId: utteranceId, rateFactor: rateFactor)
        }
        if !tracker.isSpeaking {
            // After a cancel from outside, the rest of the text must not play later.
            if !isFinished {
                engine.stop()
            }
            engine.scheduleDeactivation()
        }
        return isFinished
    }

    /// Ends the wait of the text at once. The synthesizer can skip the
    /// cancel callback for an utterance that did not start.
    func stop() {
        engine.stop()
        tracker.cancelSpeech()
    }
}

/// How one utterance ended, as the delegate of the synthesizer tells it.
private enum UtteranceEnd: Sendable {
    case finished
    case cancelled
}

/// Does all work with the synthesizer and the audio session on one serial
/// queue. These calls block: the audio session waits for the system, and
/// a Premium voice must load. On the main thread, they stop the slide to
/// the next chart. The serial queue keeps the order of "speak" and "stop".
/// All mutable state is used only on that queue.
///
/// The session does not mix with other audio. Only such an app can be the
/// app of the lock screen and get the commands of the AirPods. Thus other
/// audio stops while the voice reads. The option `duckOthers` would mix.
private final class SpeechEngine: NSObject, AVSpeechSynthesizerDelegate, @unchecked Sendable {
    private static let language = "de-DE"
    /// The time without speech before the audio session ends. It is longer
    /// than the pause of 1 s between two rows. Thus other audio does not
    /// start between two rows, and the app keeps the audio during Vorlesen,
    /// also with a locked screen.
    private static let deactivationDelay: DispatchTimeInterval = .seconds(2)

    private let queue = DispatchQueue(label: "com.kevinlandert.Kursanzeige.speech", qos: .userInitiated)
    private let synthesizer = AVSpeechSynthesizer()
    private let logger = Logger(subsystem: "com.kevinlandert.Kursanzeige", category: "Speech")
    private let reportEnd: @Sendable (Int, UtteranceEnd) -> Void
    private var voice: AVSpeechSynthesisVoice?
    private var isSessionConfigured = false
    private var isSessionActive = false
    private var deactivation: DispatchWorkItem?

    /// - Parameter reportEnd: gets the id and the end of each utterance, on
    ///   the thread of the synthesizer. The late callbacks of a stopped
    ///   text also come, and `UtteranceTracker` ignores them.
    init(reportEnd: @escaping @Sendable (Int, UtteranceEnd) -> Void) {
        self.reportEnd = reportEnd
        super.init()
        synthesizer.delegate = self
        // The voice list loads before the first tap on "Vorlesen".
        queue.async { self.voice = Self.findBestVoice() }
    }

    /// - Parameter rateFactor: the factor of „Sprechtempo“ on the default rate.
    func speak(_ text: String, utteranceId: Int, rateFactor: Float) {
        queue.async {
            self.deactivation?.cancel()
            self.deactivation = nil
            self.activateAudioSession()
            let utterance = TrackedUtterance(string: text, utteranceId: utteranceId)
            utterance.voice = self.voice
            utterance.rate = AVSpeechUtteranceDefaultSpeechRate * rateFactor
            self.synthesizer.speak(utterance)
        }
    }

    func stop() {
        queue.async { self.synthesizer.stopSpeaking(at: .immediate) }
    }

    /// Ends the audio session after `deactivationDelay`, unless a new text starts first.
    func scheduleDeactivation() {
        queue.async {
            self.deactivation?.cancel()
            let deactivation = DispatchWorkItem { self.deactivateAudioSession() }
            self.deactivation = deactivation
            self.queue.asyncAfter(deadline: .now() + Self.deactivationDelay, execute: deactivation)
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        reportEnd(of: utterance, end: .finished)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        reportEnd(of: utterance, end: .cancelled)
    }

    private func reportEnd(of utterance: AVSpeechUtterance, end: UtteranceEnd) {
        guard let trackedUtterance = utterance as? TrackedUtterance else {
            logger.error("The synthesizer ended an utterance without an id.")
            return
        }
        reportEnd(trackedUtterance.utteranceId, end)
    }

    /// A Premium or Enhanced voice from the iPad settings sounds more
    /// natural. Without a download, the default German voice reads.
    private static func findBestVoice() -> AVSpeechSynthesisVoice? {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        let installedVoices = voices.map {
            InstalledVoice(identifier: $0.identifier, language: $0.language, quality: VoiceQuality($0.quality))
        }
        guard let best = VoiceChoice.bestVoice(in: installedVoices, language: language) else {
            return AVSpeechSynthesisVoice(language: language)
        }
        return AVSpeechSynthesisVoice(identifier: best.identifier)
    }

    /// Activates the session before each text, also when the engine set it
    /// active before. iOS ends the session without a notification when it
    /// suspends the app, and after an interruption, for example a call.
    /// Then a play command of the AirPods must activate it again.
    ///
    /// Logs a failure only: the voice can still play with the default
    /// session, but maybe not in silent mode.
    private func activateAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            if !isSessionConfigured {
                try session.setCategory(.playback, mode: .spokenAudio)
                isSessionConfigured = true
            }
            try session.setActive(true)
            isSessionActive = true
        } catch {
            logger.error("Audio session for speech not active: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Lets other audio play again.
    private func deactivateAudioSession() {
        deactivation = nil
        guard isSessionActive, !synthesizer.isSpeaking else { return }
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            isSessionActive = false
        } catch {
            logger.error("Audio session for speech not ended: \(error.localizedDescription, privacy: .public)")
        }
    }
}

/// An utterance with the id of `UtteranceTracker`. The delegate reads the
/// id from the utterance, so the engine keeps no list of utterances.
private final class TrackedUtterance: AVSpeechUtterance {
    let utteranceId: Int

    init(string: String, utteranceId: Int) {
        self.utteranceId = utteranceId
        super.init(string: string)
    }

    /// The app never decodes an utterance.
    required init?(coder: NSCoder) {
        nil
    }
}

private extension VoiceQuality {
    init(_ quality: AVSpeechSynthesisVoiceQuality) {
        switch quality {
        case .premium: self = .premium
        case .enhanced: self = .enhanced
        default: self = .standard
        }
    }
}
