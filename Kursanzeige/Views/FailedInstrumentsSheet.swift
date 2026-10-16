import SwiftUI
import KursanzeigeKit

/// Lists exactly which instruments failed to load on the last refresh, and
/// why, so "3 von 53 nicht geladen" stops being a mystery. Large, simple
/// text -- this is a detail view, not a redesign of the main table.
struct FailedInstrumentsSheet: View {
    let failedFetches: [FailedFetch]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(failedFetches) { failure in
                VStack(alignment: .leading, spacing: 4) {
                    Text(failure.instrument.name)
                        .font(Theme.font(size: 24))
                    Text("\(failure.instrument.symbol) · \(failure.instrument.group.displayName)")
                        .font(Theme.font(size: 18))
                        .foregroundStyle(Theme.mutedText)
                    Text(failure.reason)
                        .font(Theme.font(size: 18))
                        .foregroundStyle(Theme.negative)
                }
                .padding(.vertical, 6)
            }
            .navigationTitle("Nicht geladen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // The same large title in the app font as on the settings
                // page.
                ToolbarItem(placement: .principal) {
                    Text("Nicht geladen")
                        .font(Theme.font(size: 32))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                        .font(Theme.font(size: 20))
                }
            }
        }
    }
}

#Preview {
    FailedInstrumentsSheet(failedFetches: [
        FailedFetch(instrument: Instrument(symbol: "RO.SW", name: "Roche", group: .switzerland), reason: "Symbol nicht gefunden"),
        FailedFetch(instrument: Instrument(symbol: "^SSMI", name: "SMI", group: .index), reason: "Zu viele Anfragen (Rate-Limit)"),
    ])
}
