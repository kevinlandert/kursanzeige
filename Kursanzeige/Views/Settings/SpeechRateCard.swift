import KursanzeigeKit
import SwiftUI

/// „Sprechtempo“: [Langsamer] value [Schneller] over „Probe hören“. The
/// sample reads the cursor row of the table with the chosen columns.
struct SpeechRateCard: View {
    let appModel: AppModel
    @AppStorage(SpeechRate.storageKey) private var speechRate = SpeechRate.standard

    var body: some View {
        SettingsCard(title: "Sprechtempo") {
            EqualColumnsLayout(spacing: Theme.settingsButtonSpacing) {
                stepButton("Langsamer", hint: "Die Stimme liest langsamer.", limitHint: "Das ist schon das langsamste Tempo.", newRate: speechRate.slowerRate)
                valueCell
                stepButton("Schneller", hint: "Die Stimme liest schneller.", limitHint: "Das ist schon das schnellste Tempo.", newRate: speechRate.fasterRate)
            }
            sampleButton
        }
    }

    /// One adjustable element for VoiceOver: a swipe up or down changes the tempo.
    private var valueCell: some View {
        SettingsButtonLabel(text: speechRate.displayName)
            .background(Theme.neutralFill, in: RoundedRectangle(cornerRadius: Theme.bottomButtonCornerRadius))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Sprechtempo")
            .accessibilityValue(speechRate.displayName)
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: changeRate(to: speechRate.fasterRate)
                case .decrement: changeRate(to: speechRate.slowerRate)
                @unknown default: break
                }
            }
    }

    /// Grey and without effect at the slowest or the fastest tempo. The
    /// button stays focusable, so VoiceOver keeps its focus on it, and the
    /// hint tells the limit.
    private func stepButton(_ title: String, hint: String, limitHint: String, newRate: SpeechRate?) -> some View {
        Button {
            guard let newRate else { return }
            changeRate(to: newRate)
            AccessibilityNotification.Announcement(newRate.displayName).post()
        } label: {
            SettingsButtonLabel(text: title)
        }
        .buttonStyle(ControlButtonStyle(look: newRate == nil ? .disabled : .outlined))
        .accessibilityHint(newRate == nil ? limitHint : hint)
    }

    /// A sample that plays stops: the new tempo applies only to the next text.
    private func changeRate(to newRate: SpeechRate?) {
        guard let newRate else { return }
        speechRate = newRate
        appModel.stopSample()
    }

    /// A second press stops the sample.
    private var sampleButton: some View {
        let isPlaying = appModel.isPlayingSample
        return Button(action: appModel.toggleSample) {
            Label(isPlaying ? "Probe stoppen" : "Probe hören", systemImage: isPlaying ? "stop.fill" : "speaker.wave.2")
                .font(Theme.settingsButtonFont)
                .frame(maxWidth: .infinity, minHeight: Theme.settingsButtonHeight)
        }
        .buttonStyle(ControlButtonStyle(look: .primary))
        .accessibilityHint(isPlaying ? "Hält die Probe an." : "Liest die ausgewählte Zeile im gewählten Tempo vor.")
        .accessibilityIdentifier("sampleButton")
    }
}
