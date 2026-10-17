import SwiftUI

/// The progress of a refresh: a bar and the percent in digits. A bar
/// alone is hard to read for a person with low vision. It shows under
/// „Kurse“ in place of the time of the last refresh. It has a fixed width.
struct RefreshProgressView: View {
    let progress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ProgressView(value: progress)
                .tint(Theme.accent)
                .frame(width: 160)
            Text("\(Int((progress * 100).rounded())) % geladen")
                .font(Theme.progressFont)
                .monospacedDigit()
        }
    }
}

#Preview {
    RefreshProgressView(progress: 0.42)
        .padding()
}
