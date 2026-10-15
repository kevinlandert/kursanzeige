import SwiftUI
import KursanzeigeKit

/// The sun or moon icon next to the settings button. A tap changes the
/// full app from light to dark, or back. The icon shows the appearance
/// that is on now: a sun for light, a moon for dark.
struct AppearanceButton: View {
    let appearance: Appearance
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            TopBarIcon(systemName: appearance == .dark ? "moon.fill" : "sun.max.fill")
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Dunkle Darstellung")
        .accessibilityValue(appearance == .dark ? "Ein" : "Aus")
        .accessibilityIdentifier("appearance")
    }
}

#Preview {
    HStack(spacing: 20) {
        AppearanceButton(appearance: .light) {}
        AppearanceButton(appearance: .dark) {}
    }
    .padding()
}
