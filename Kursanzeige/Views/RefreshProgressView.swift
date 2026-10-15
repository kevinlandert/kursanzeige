import SwiftUI

/// Large, unambiguous "how far along is the refresh" indicator -- a bar
/// plus the percentage spelled out in digits, since a bar alone is hard to
/// read precisely at a glance for someone with low vision. Lives inline in
/// the top bar next to the settings button, so it needs a fixed width
/// rather than stretching to fill the row (which is what it did in its
/// previous spot, a full-width row of its own).
struct RefreshProgressView: View {
    let progress: Double

    var body: some View {
        VStack(spacing: 8) {
            ProgressView(value: progress)
                .tint(Color.accentColor)
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
