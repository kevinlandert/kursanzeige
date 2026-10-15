import SwiftUI

/// The "Aktualisieren" button, top right. During a refresh, the button
/// shows "Lädt…" and does not accept a tap. A second tap would start a
/// second fetch. The view model also prevents this, but the button must
/// show it.
struct RefreshButton: View {
    let isRefreshing: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            // The hidden "Aktualisieren" keeps the width of the button while
            // "Lädt…" shows. Thus the icon buttons on the left do not move.
            ZStack {
                label("Aktualisieren").hidden()
                HStack(spacing: 10) {
                    if isRefreshing {
                        ProgressView()
                            .tint(Theme.buttonText)
                    }
                    label(isRefreshing ? "Lädt…" : "Aktualisieren")
                }
            }
            // A fixed height for the content, with or without the spinner.
            // The spinner is higher than the text. Without this frame, the
            // button and all below it move down during a refresh.
            .frame(height: 32)
            .padding(.horizontal, 28)
            .padding(.vertical, 18)
            .background(Theme.action)
            .foregroundStyle(Theme.buttonText)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
        }
        .buttonStyle(.plain)
        // The button never gets narrower when the top bar is full. A text on
        // the left gets a second line.
        .fixedSize()
        .disabled(isRefreshing)
        .accessibilityIdentifier("refresh")
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .font(Theme.refreshButtonFont)
            .lineLimit(1)
    }
}

#Preview {
    VStack(spacing: 20) {
        RefreshButton(isRefreshing: false, action: {})
        RefreshButton(isRefreshing: true, action: {})
    }
    .padding()
}
