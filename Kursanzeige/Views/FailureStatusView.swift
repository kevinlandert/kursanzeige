import SwiftUI
import KursanzeigeKit

/// Shown after a refresh finishes with some symbols still unreadable
/// despite retries -- e.g. "3 von 53 nicht geladen". Those rows keep
/// showing their last known value; this just makes the gap visible rather
/// than silent. The "?" button answers the obvious next question --
/// which ones, and why -- without cluttering the status line itself.
struct FailureStatusView: View {
    let failedFetches: [FailedFetch]
    let totalCount: Int

    @State private var showingDetail = false

    var body: some View {
        HStack(spacing: 8) {
            Text("\(failedFetches.count) von \(totalCount) nicht geladen")
                .font(Theme.statusFont)
                .foregroundStyle(Theme.negative)

            Button {
                showingDetail = true
            } label: {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Theme.negative)
            }
            .accessibilityLabel("Welche Werte nicht geladen wurden anzeigen")
        }
        // The top bar keeps this height free, so the table does not move.
        .frame(height: Theme.failureStatusHeight)
        .sheet(isPresented: $showingDetail) {
            FailedInstrumentsSheet(failedFetches: failedFetches)
        }
    }
}

#Preview {
    FailureStatusView(
        failedFetches: [
            FailedFetch(instrument: Instrument(symbol: "RO.SW", name: "Roche", group: .switzerland), reason: "Symbol nicht gefunden")
        ],
        totalCount: 53
    )
    .padding()
}
