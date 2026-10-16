import AVFoundation
import KursanzeigeKit
import os

/// `Speaking` with the iOS speech synthesizer and a German voice. The
/// voice plays as spoken audio, so it is audible also in silent mode.
/// While it reads, other audio such as music is quieter. `MainView` makes
/// one for the full app life: a speaker that stays in memory always gets
/// the stop callback, and then gives other audio its full volume again.
@MainActor
final class SynthesizerSpeaker: Speaking {
    private let engine = SpeechEngine()

    func speak(_ text: String) {
        engine.speak(text)
    }

    func stop() {
        engine.stop()
    }
}

/// Does all work with the synthesizer and the audio session on one
/// serial queue. These calls block: the audio session waits for the
/// system, and a Premium voice must load. On the main thread, they stop
/// the slide to the next chart. The serial queue keeps the order of
/// "stop" and "speak". All mutable state is used only on that queue.
private final class SpeechEngine: NSObject, AVSpeechSynthesizerDelegate, @unchecked Sendable {
    /// A bit faster than the default voice, so a full table does not take
    /// too long.
    private static let speechRateFactor: Float = 1.1
    private static let language = "de-DE"

    private let queue = DispatchQueue(label: "com.kevinlandert.Kursanzeige.speech", qos: .userInitiated)
    private let synthesizer = AVSpeechSynthesizer()
    private let logger = Logger(subsystem: "com.kevinlandert.Kursanzeige", category: "Speech")
    private var voice: AVSpeechSynthesisVoice?
    /// A swipe stops one text and starts the next. The session then stays
    /// active, so the second text needs no new activation.
    private var isSessionActive = false
    /// The texts given to the synthesizer that did not finish and were not
    /// stopped. `isSpeaking` is not enough: the stop callback of the old
    /// text comes after the new text starts, while `isSpeaking` is still
    /// false. An end of the session at that time cuts the first words of
    /// the new text.
    private var unfinishedTextCount = 0

    override init() {
        super.init()
        synthesizer.delegate = self
        // The voice list loads before the first tap on "Vorlesen".
        queue.async { self.voice = Self.findBestVoice() }
    }

    func speak(_ text: String) {
        queue.async {
            self.activateAudioSession()
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = self.voice
            utterance.rate = AVSpeechUtteranceDefaultSpeechRate * Self.speechRateFactor
            self.unfinishedTextCount += 1
            self.synthesizer.speak(utterance)
        }
    }

    func stop() {
        queue.async { self.synthesizer.stopSpeaking(at: .immediate) }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        queue.async { self.endText() }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        queue.async { self.endText() }
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

    /// Logs a failure only: the voice can still play with the default
    /// session, but maybe not in silent mode.
    private func activateAudioSession() {
        guard !isSessionActive else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            isSessionActive = true
        } catch {
            logger.error("Audio session for speech not active: \(error.localizedDescription)")
        }
    }

    /// Gives other audio its full volume again after the last text. Not
    /// while a new text plays: "Nächster" stops the old text and starts
    /// the new one at once.
    private func endText() {
        unfinishedTextCount = max(unfinishedTextCount - 1, 0)
        guard isSessionActive, unfinishedTextCount == 0 else { return }
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            isSessionActive = false
        } catch {
            logger.error("Audio session for speech not ended: \(error.localizedDescription)")
        }
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
