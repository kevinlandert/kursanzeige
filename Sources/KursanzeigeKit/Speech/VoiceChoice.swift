/// The sound quality of a speech voice. The person can download an
/// Enhanced or a Premium voice in the iPad settings.
public enum VoiceQuality: Int, Comparable, Sendable {
    case standard
    case enhanced
    case premium

    public static func < (lhs: VoiceQuality, rhs: VoiceQuality) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// A speech voice on the device, without the iOS voice object.
public struct InstalledVoice: Equatable, Sendable {
    public let identifier: String
    /// A BCP 47 code, e.g. "de-DE".
    public let language: String
    public let quality: VoiceQuality

    public init(identifier: String, language: String, quality: VoiceQuality) {
        self.identifier = identifier
        self.language = language
        self.quality = quality
    }
}

/// Finds the voice that reads the prices aloud.
public enum VoiceChoice {
    /// The voice in `language` with the best quality. Of two voices with
    /// the same quality, the first in `voices` wins. `nil` when no voice
    /// has that language.
    public static func bestVoice(in voices: [InstalledVoice], language: String) -> InstalledVoice? {
        voices
            .filter { $0.language == language }
            .reduce(nil) { best, voice in
                guard let best, best.quality >= voice.quality else { return voice }
                return best
            }
    }
}
