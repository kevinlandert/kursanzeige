import SwiftUI

/// The three looks of a bottom button, as in Schlagzeilen.
enum ControlLook {
    /// Text color on the page with an outline: Vorherige and Nächste.
    case outlined
    /// White on blue: Vorlesen and Pause.
    case primary
    /// The inverted fill: Öffnen and Schliessen. It is black in light and
    /// white in dark.
    case inverted

    var fill: Color {
        switch self {
        case .outlined: Theme.background
        case .primary: Theme.primary
        case .inverted: Theme.invertedFill
        }
    }

    var text: Color {
        switch self {
        case .outlined: Theme.text
        case .primary: Theme.primaryText
        case .inverted: Theme.invertedText
        }
    }

    var border: Color {
        switch self {
        case .outlined: Theme.outline
        case .primary: Theme.primary
        case .inverted: Theme.invertedFill
        }
    }
}

/// The button style of the bottom buttons. A pressed button becomes a
/// little smaller. Its colors stay, so the contrast stays.
struct ControlButtonStyle: ButtonStyle {
    static let pressedScale = 0.97

    let look: ControlLook

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: Theme.bottomButtonCornerRadius)
        configuration.label
            .foregroundStyle(look.text)
            .background(look.fill, in: shape)
            .overlay(shape.strokeBorder(look.border, lineWidth: Theme.bottomButtonBorderWidth))
            .contentShape(shape)
            .scaleEffect(configuration.isPressed ? Self.pressedScale : 1)
    }
}
