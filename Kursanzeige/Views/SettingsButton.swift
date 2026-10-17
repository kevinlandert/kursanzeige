import SwiftUI

/// „Einstellungen“ next to „Aktualisieren“ in the top bar, with a text, as
/// in Schlagzeilen. A tap opens the settings: the reader changes the
/// Erscheinungsbild and the Sprechtempo there.
struct SettingsButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Einstellungen", systemImage: "gearshape")
                .font(Theme.refreshButtonFont)
                .padding(.horizontal, Theme.textButtonPadding)
                .frame(height: Theme.topBarHeight)
        }
        .buttonStyle(ControlButtonStyle(look: .outlined))
        .accessibilityHint("Zeigt das Erscheinungsbild, das Sprechtempo und die Spalten.")
        .accessibilityIdentifier("settingsButton")
    }
}

#Preview {
    SettingsButton(action: {})
        .padding()
}
