import SwiftUI

/// A card of the settings with a title, for example „Sprechtempo“. It
/// fills the height that its parent gives it.
struct SettingsCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Theme.settingsCardCornerRadius)
        VStack(alignment: .leading, spacing: Theme.settingsCardSpacing) {
            Text(title)
                .font(Theme.settingsCardTitleFont)
                .foregroundStyle(Theme.text)
                .accessibilityAddTraits(.isHeader)
            content
        }
        .padding(Theme.settingsCardPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.background, in: shape)
        .overlay(shape.strokeBorder(Theme.separator, lineWidth: Theme.settingsCardBorderWidth))
    }
}

/// The text of a settings button. It fills its column.
struct SettingsButtonLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(Theme.settingsButtonFont)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, Theme.choiceButtonTextInset)
            .frame(maxWidth: .infinity, minHeight: Theme.settingsButtonHeight)
    }
}

/// A choice of a row of settings buttons, e.g. „Dunkel“: blue when
/// selected, as the group buttons. VoiceOver reads it as selected.
struct SettingsChoiceButton: View {
    let title: String
    let isSelected: Bool
    let hint: String
    let identifier: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            SettingsButtonLabel(text: title)
                .choiceButtonLook(isSelected: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityHint(hint)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityIdentifier(identifier)
    }
}
