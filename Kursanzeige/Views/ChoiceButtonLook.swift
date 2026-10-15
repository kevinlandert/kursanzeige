import SwiftUI

extension View {
    /// The look of a button in a row of choices: blue with white text when
    /// selected, grey with a border when not selected. The grey is almost
    /// the same as the page, so the border shows the button.
    func choiceButtonLook(isSelected: Bool) -> some View {
        background(isSelected ? Theme.accent : Theme.headerBackground)
            .foregroundStyle(isSelected ? Theme.buttonText : Theme.text)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
            .greyButtonBorder(isShown: !isSelected)
    }

    /// The border of a grey button that accepts a tap. A disabled grey
    /// button has no border, so it looks different.
    func greyButtonBorder(isShown: Bool = true) -> some View {
        overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(isShown ? Theme.buttonBorder : Color.clear, lineWidth: Theme.buttonBorderWidth)
        )
    }
}
