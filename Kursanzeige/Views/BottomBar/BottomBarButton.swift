import SwiftUI

/// Where the symbol of a bottom button is in the inline layout.
enum SymbolPlacement {
    case leading
    case trailing
}

/// How a bottom button puts its symbol and its text.
enum LabelLayout {
    /// The symbol next to the text.
    case inline
    /// The symbol over the text, when the four buttons are too narrow.
    case stacked
}

/// What one bottom button shows and does.
struct BottomButtonContent {
    let title: String
    let symbolName: String
    let placement: SymbolPlacement
    let look: ControlLook
    let hint: String
    let identifier: String
    let action: () -> Void
}

/// One of the four buttons of the bottom bar, at least 96 pt high. In the
/// stacked layout a long text can become a little smaller. It never leaves
/// the button.
struct BottomBarButton: View {
    let content: BottomButtonContent
    let layout: LabelLayout

    var body: some View {
        Button(action: content.action) {
            label
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, Theme.bottomButtonHorizontalPadding)
                .frame(maxWidth: .infinity, minHeight: Theme.bottomButtonHeight)
        }
        .buttonStyle(ControlButtonStyle(look: content.look))
        .accessibilityLabel(content.title)
        .accessibilityHint(content.hint)
        .accessibilityIdentifier(content.identifier)
    }

    @ViewBuilder
    private var label: some View {
        switch layout {
        case .inline:
            HStack(spacing: Theme.bottomButtonSymbolSpacing) {
                if content.placement == .leading { symbol }
                title
                if content.placement == .trailing { symbol }
            }
        case .stacked:
            VStack(spacing: 4) {
                symbol
                title
            }
        }
    }

    private var symbol: some View {
        Image(systemName: content.symbolName)
            .font(Theme.bottomButtonSymbolFont)
            .accessibilityHidden(true)
    }

    private var title: some View {
        Text(content.title)
            .font(Theme.bottomButtonFont)
    }
}
