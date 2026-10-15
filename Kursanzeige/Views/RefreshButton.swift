import SwiftUI

/// The "Aktualisieren" button, top right. Disabled and re-labeled while a
/// refresh is running, since re-tapping mid-refresh would start a second
/// overlapping fetch (the view model also guards against that, but the
/// button should visibly reflect it).
struct RefreshButton: View {
    let isRefreshing: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isRefreshing {
                    ProgressView()
                        .tint(.white)
                }
                Text(isRefreshing ? "Lädt…" : "Aktualisieren")
                    .font(Theme.refreshButtonFont)
                    .lineLimit(1)
            }
            // Pins the button's content to one height regardless of
            // whether the spinner is present -- without this, the spinner's
            // intrinsic size differs from the text's line height, so the
            // whole button (and everything below it, since topBar sits at
            // the top of a plain VStack) shifted down while refreshing and
            // back up when it finished.
            .frame(height: 32)
            .padding(.horizontal, 28)
            .padding(.vertical, 18)
            .background(Theme.positive)
            .foregroundStyle(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
        }
        .buttonStyle(.plain)
        .disabled(isRefreshing)
    }
}

#Preview {
    VStack(spacing: 20) {
        RefreshButton(isRefreshing: false, action: {})
        RefreshButton(isRefreshing: true, action: {})
    }
    .padding()
}
