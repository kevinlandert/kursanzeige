import KursanzeigeKit
import SwiftUI

/// The line above the bottom buttons: „Nummer 3 von 8 ausgewählt“ in the
/// text color on the neutral fill, or „Liest vor · …“ in white on blue
/// while the app reads. VoiceOver reads it as one element.
struct StatusLine: View {
    let text: String
    let style: StatusStyle

    var body: some View {
        HStack(spacing: Theme.statusLineHorizontalPadding) {
            Image(systemName: "speaker.wave.2")
                .font(Theme.bottomButtonSymbolFont)
                .accessibilityHidden(true)
            Text(text)
                .font(Theme.statusLineFont)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .foregroundStyle(style == .reading ? Theme.primaryText : Theme.text)
        .padding(.horizontal, Theme.statusLineHorizontalPadding)
        .padding(.vertical, Theme.statusLineVerticalPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(style == .reading ? Theme.primary : Theme.neutralFill, in: RoundedRectangle(cornerRadius: Theme.statusLineCornerRadius))
        .accessibilityElement(children: .combine)
    }
}
