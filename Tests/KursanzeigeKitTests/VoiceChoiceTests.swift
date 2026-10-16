import Testing
@testable import KursanzeigeKit

/// A downloaded Premium or Enhanced voice sounds more natural than the
/// default voice. The app uses the best German voice on the iPad.
@Suite("VoiceChoice")
struct VoiceChoiceTests {
    private let anna = InstalledVoice(identifier: "anna-default", language: "de-DE", quality: .standard)
    private let petraEnhanced = InstalledVoice(identifier: "petra-enhanced", language: "de-DE", quality: .enhanced)
    private let annaPremium = InstalledVoice(identifier: "anna-premium", language: "de-DE", quality: .premium)
    private let samanthaPremium = InstalledVoice(identifier: "samantha-premium", language: "en-US", quality: .premium)

    @Test("a Premium voice comes before an Enhanced and a default voice")
    func premiumVoiceComesFirst() {
        let voices = [anna, petraEnhanced, annaPremium]
        #expect(VoiceChoice.bestVoice(in: voices, language: "de-DE") == annaPremium)
    }

    @Test("without a Premium voice, an Enhanced voice comes before a default voice")
    func enhancedVoiceComesBeforeDefault() {
        let voices = [anna, petraEnhanced]
        #expect(VoiceChoice.bestVoice(in: voices, language: "de-DE") == petraEnhanced)
    }

    @Test("a voice of an other language is never the choice, also in Premium quality")
    func otherLanguageIsNeverTheChoice() {
        let voices = [anna, samanthaPremium]
        #expect(VoiceChoice.bestVoice(in: voices, language: "de-DE") == anna)
    }

    @Test("of two voices with the same quality, the first in the list is the choice")
    func firstVoiceWinsAtSameQuality() {
        let markusPremium = InstalledVoice(identifier: "markus-premium", language: "de-DE", quality: .premium)
        let voices = [markusPremium, annaPremium]
        #expect(VoiceChoice.bestVoice(in: voices, language: "de-DE") == markusPremium)
    }

    @Test("without a voice in the language there is no choice")
    func noVoiceInLanguageGivesNoChoice() {
        #expect(VoiceChoice.bestVoice(in: [samanthaPremium], language: "de-DE") == nil)
    }
}
