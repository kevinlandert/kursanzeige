import SwiftUI

/// The gear icon next to "Aktualisieren", top bar. Opens the settings
/// sheet (display-mode toggles + list customization).
struct SettingsButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            TopBarIcon(systemName: "gearshape.fill")
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Einstellungen öffnen")
    }
}

#Preview {
    SettingsButton(action: {})
        .padding()
}
