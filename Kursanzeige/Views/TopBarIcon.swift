import SwiftUI

/// A grey square with a large symbol and a border. The look of each icon
/// button in the top bar. The fixed symbol frame keeps the size of the
/// button when the symbol changes, so the top bar does not move.
struct TopBarIcon: View {
    let systemName: String

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 26, weight: .semibold))
            .frame(width: 34, height: 34)
            .padding(18)
            .background(Theme.headerBackground)
            .foregroundStyle(Theme.text)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
            .greyButtonBorder()
    }
}
