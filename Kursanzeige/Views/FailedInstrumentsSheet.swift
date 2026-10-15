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
                        .font(.system(size: 24, weight: .semibold))
                    Text("\(failure.instrument.symbol) · \(failure.instrument.group.displayName)")
                        .font(.system(size: 18))
                        .foregroundStyle(.secondary)
                    Text(failure.reason)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Theme.negative)
                }
                .padding(.vertical, 6)
            }
            .navigationTitle("Nicht geladen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                        .font(.system(size: 20, weight: .semibold))
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
