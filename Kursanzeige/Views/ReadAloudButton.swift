import SwiftUI

/// The big "Vorlesen" button below the table and above "Vorheriger" and
/// "Nächster" on the chart page. A tap sets read aloud on and reads the
/// page. The next tap stops the voice.
/// On: blue with white sound waves. Off: grey with a speaker in text color and a
/// border, so it does not look like a disabled button.
struct ReadAloudButton: View {
    let isOn: Bool
    /// Each page has its own value, so a UI test finds the right button.
    let identifier: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isOn ? "speaker.wave.3.fill" : "speaker.wave.2")
                .font(.system(size: Theme.readAloudIconSize, weight: .bold))
                .frame(width: Theme.readAloudButtonWidth, height: Theme.readAloudButtonHeight)
                .background(isOn ? Theme.accent : Theme.headerBackground)
                .foregroundStyle(isOn ? Theme.buttonText : Theme.text)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cornerRadius)
                        .stroke(isOn ? Color.clear : Theme.text, lineWidth: Theme.chartBorderWidth)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Vorlesen")
        .accessibilityValue(isOn ? "Ein" : "Aus")
        .accessibilityIdentifier(identifier)
    }
}

#Preview {
    VStack(spacing: 20) {
        ReadAloudButton(isOn: false, identifier: "readAloud") {}
        ReadAloudButton(isOn: true, identifier: "readAloud") {}
    }
    .padding()
}
