import SwiftUI
import KursanzeigeKit

/// The five group buttons ("Währungen", "Schweiz", "USA", "Europa", "Welt").
/// The selected one is filled solid rather than just tinted, so which group
/// is showing is obvious without reading text.
struct GroupSelectorView: View {
    let selected: MarketGroup
    let onSelect: (MarketGroup) -> Void

    var body: some View {
        HStack(spacing: 10) {
            ForEach(MarketGroup.allCases) { group in
                Button {
                    onSelect(group)
                } label: {
                    Text(group.displayName)
                        .font(Theme.groupButtonFont)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .choiceButtonLook(isSelected: group == selected)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(group == selected ? [.isSelected] : [])
            }
        }
    }
}

#Preview {
    GroupSelectorView(selected: .switzerland, onSelect: { _ in })
        .padding()
}
