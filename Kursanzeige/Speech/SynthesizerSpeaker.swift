import AVFoundation
import KursanzeigeKit
import os

/// `Speaking` with the iOS speech synthesizer and a German voice. The
/// voice plays as spoken audio, so it is audible also in silent mode.
/// While it reads, other audio such as music is quieter. `MainView` makes
/// one for the full app life: a speaker that stays in memory always gets
/// the stop callback, and then gives other audio its full volume again.
@MainActor
final class SynthesizerSpeaker: NSObject, Speaking {
    /// A bit slower than the default voice, so each number is clear.
    private static let speechRateFactor: Float = 0.9

    private let synthesizer = AVSpeechSynthesizer()
    private let voice = AVSpeechSynthesisVoice(language: "de-DE")
    private let logger = Logger(subsystem: "com.kevinlandert.Kursanzeige", category: "Speech")

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ text: String) {
        activateAudioSession()
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * Self.speechRateFactor
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    /// Logs a failure only: the voice can still play with the default
    /// session, but maybe not in silent mode.
    private func activateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            logger.error("Audio session for speech not active: \(error.localizedDescription)")
        }
    }

    /// Gives other audio its full volume again. Not while a new text
    /// plays: "Nächster" stops the old text and starts the new one at once.
    fileprivate func deactivateAudioSessionWhenSilent() {
        guard !synthesizer.isSpeaking else { return }
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            logger.error("Audio session for speech not ended: \(error.localizedDescription)")
        }
    }
}

extension SynthesizerSpeaker: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in self.deactivateAudioSessionWhenSilent() }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in self.deactivateAudioSessionWhenSilent() }
    }
}
