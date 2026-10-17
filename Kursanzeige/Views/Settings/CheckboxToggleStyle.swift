import SwiftUI

/// A large checkbox with its label. The full row is the target. Blue with
/// a white check mark when on, an outline when off. A disabled box is grey
/// with a check mark, e.g. the name that is always read. VoiceOver gets a
/// standard switch, so it reads the state and a double tap changes it.
struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        CheckboxRow(configuration: configuration)
    }
}

private struct CheckboxRow: View {
    let configuration: ToggleStyleConfiguration
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: Theme.settingsButtonSpacing) {
                box
                configuration.label
            }
            .frame(minHeight: Theme.settingsButtonHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityRepresentation {
            Toggle(isOn: configuration.$isOn) { configuration.label }
        }
    }

    private var box: some View {
        let shape = RoundedRectangle(cornerRadius: Theme.settingsCheckboxCornerRadius)
        let isFilled = configuration.isOn && isEnabled
        return Image(systemName: "checkmark")
            .font(Theme.settingsCheckmarkFont)
            .foregroundStyle(isFilled ? Theme.primaryText : Theme.text)
            .opacity(configuration.isOn ? 1 : 0)
            .frame(width: Theme.settingsCheckboxSize, height: Theme.settingsCheckboxSize)
            .background(isFilled ? Theme.primary : (isEnabled ? Theme.background : Theme.headerBackground), in: shape)
            .overlay(shape.strokeBorder(isFilled ? Theme.primary : (isEnabled ? Theme.outline : Theme.buttonBorder), lineWidth: Theme.bottomButtonBorderWidth))
    }
}
