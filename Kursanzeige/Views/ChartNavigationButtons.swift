import SwiftUI

/// "Vorheriger" and "Nächster" below the chart. They open the chart of the
/// row above or below in the table, without a return to the table. A `nil`
/// action greys its button out: the first row has no previous row, the
/// last row has no next row.
struct ChartNavigationButtons: View {
    let onPrevious: (() -> Void)?
    let onNext: (() -> Void)?

    var body: some View {
        HStack(spacing: 16) {
            navigationButton(action: onPrevious) {
                Image(systemName: "chevron.left")
                Text("Vorheriger")
            }
            navigationButton(action: onNext) {
                Text("Nächster")
                Image(systemName: "chevron.right")
            }
        }
    }

    private func navigationButton(action: (() -> Void)?, @ViewBuilder label: () -> some View) -> some View {
        let isEnabled = action != nil
        return Button {
            action?()
        } label: {
            HStack(spacing: 12) { label() }
                .font(Theme.chartNavigationFont)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 22)
                .background(isEnabled ? Color.accentColor : Theme.headerBackground)
                .foregroundStyle(isEnabled ? Color.white : Theme.disabledButtonForeground)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

#Preview {
    VStack(spacing: 20) {
        ChartNavigationButtons(onPrevious: nil, onNext: {})
        ChartNavigationButtons(onPrevious: {}, onNext: nil)
    }
    .padding()
}
