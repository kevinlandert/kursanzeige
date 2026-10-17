import KursanzeigeKit
import SwiftUI

/// The settings page, made of cards. The order follows who uses what. The
/// reader changes the first two cards: Erscheinungsbild and Sprechtempo.
/// Then come the table columns and what the voice reads. The list of
/// instruments is last, because a helper usually sets it. In landscape
/// the first two cards are side by side.
struct SettingsView: View {
    let appModel: AppModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            header
            Rectangle()
                .fill(Theme.text)
                .frame(height: Theme.bottomBarRuleWidth)
            GeometryReader { geometry in
                ScrollView {
                    cards(isLandscape: geometry.size.width > geometry.size.height)
                        .padding(Theme.settingsGap)
                }
            }
        }
        .background(Theme.background)
    }

    /// „‹ Kurse“ goes back to the table.
    private var header: some View {
        HStack(spacing: Theme.settingsGap) {
            Button(action: { dismiss() }) {
                Label("Kurse", systemImage: "chevron.left")
                    .font(Theme.settingsButtonFont)
                    .padding(.horizontal, Theme.textButtonPadding)
                    .frame(minHeight: Theme.topBarHeight)
            }
            .buttonStyle(ControlButtonStyle(look: .outlined))
            .accessibilityHint("Schliesst die Einstellungen und zeigt wieder die Tabelle.")
            .accessibilityIdentifier("settingsCloseButton")
            Text("Einstellungen")
                .font(Theme.settingsTitleFont)
                .foregroundStyle(Theme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Theme.settingsGap)
        .frame(height: Theme.settingsHeaderHeight)
    }

    @ViewBuilder
    private func cards(isLandscape: Bool) -> some View {
        VStack(spacing: Theme.settingsGap) {
            if isLandscape {
                // Both cards take the height of the higher one.
                HStack(alignment: .top, spacing: Theme.settingsGap) {
                    AppearanceCard()
                    SpeechRateCard(appModel: appModel)
                }
                .fixedSize(horizontal: false, vertical: true)
            } else {
                AppearanceCard()
                SpeechRateCard(appModel: appModel)
            }
            TableSpeechCard(appModel: appModel)
            InstrumentsCard(viewModel: appModel.viewModel)
        }
    }
}

#Preview {
    SettingsView(appModel: AppModel())
}
