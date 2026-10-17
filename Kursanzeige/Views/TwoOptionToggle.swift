import SwiftUI

/// A big two-option toggle: each option is its own full-width button,
/// filled when active. Built as plain buttons rather than a native
/// segmented `Picker` -- `UISegmentedControl` silently caps how large its
/// label text renders regardless of the `.font()` modifier, which fights
/// the "make it way bigger" requirement this screen exists for. Same
/// visual language as `GroupSelectorView`'s buttons.
///
/// VoiceOver reads the spoken labels, e.g. „ein Monat“ for „1 Monat“.
struct TwoOptionToggle<Option: Equatable>: View {
    let leftLabel: String
    let leftSpokenLabel: String
    let leftValue: Option
    let rightLabel: String
    let rightSpokenLabel: String
    let rightValue: Option
    let selection: Option
    let font: Font
    let onSelect: (Option) -> Void

    var body: some View {
        HStack(spacing: 10) {
            optionButton(leftLabel, spokenLabel: leftSpokenLabel, value: leftValue)
            optionButton(rightLabel, spokenLabel: rightSpokenLabel, value: rightValue)
        }
    }

    private func optionButton(_ title: String, spokenLabel: String, value: Option) -> some View {
        let isActive = selection == value
        return Button {
            onSelect(value)
        } label: {
            Text(title)
                .font(font)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .choiceButtonLook(isSelected: isActive)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(spokenLabel)
        .accessibilityAddTraits(isActive ? [.isSelected] : [])
    }
}

#Preview {
    TwoOptionToggle(
        leftLabel: "1 Monat", leftSpokenLabel: "ein Monat", leftValue: 0,
        rightLabel: "3 Monate", rightSpokenLabel: "3 Monate", rightValue: 1,
        selection: 1, font: .system(size: 26, weight: .medium)
    ) { _ in }
        .padding()
}
