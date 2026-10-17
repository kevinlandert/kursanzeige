import KursanzeigeKit
import SwiftUI

/// „Erscheinungsbild“: [Hell] [Dunkel] [Wie iPad] over a line that tells
/// what the app does. The reader changes it, so it is the first card.
struct AppearanceCard: View {
    @AppStorage(Appearance.storageKey) private var appearance = Appearance.standard
    /// With „Wie iPad“ the app has no own style, so this is the mode of the iPad.
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        SettingsCard(title: "Erscheinungsbild") {
            EqualColumnsLayout(spacing: Theme.settingsButtonSpacing) {
                ForEach(Appearance.allCases, id: \.self) { choice in
                    SettingsChoiceButton(
                        title: choice.displayName, isSelected: choice == appearance,
                        hint: "Ändert die Farben der App.", identifier: "appearanceChoice.\(choice.rawValue)"
                    ) {
                        appearance = choice
                    }
                }
            }
            Text(appearance.hint(isDeviceDark: colorScheme == .dark))
                .font(Theme.settingsHintFont)
                .foregroundStyle(Theme.mutedText)
                .accessibilityIdentifier("appearanceHint")
        }
    }
}
