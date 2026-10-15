import SwiftUI

/// The gear icon next to "Aktualisieren", top bar. Opens the settings
/// sheet (display-mode toggles + list customization).
struct SettingsButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 26, weight: .semibold))
                .padding(18)
                .background(Theme.headerBackground)
                .foregroundStyle(Color.primary)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Einstellungen öffnen")
    }
}

#Preview {
    SettingsButton(action: {})
        .padding()
}
