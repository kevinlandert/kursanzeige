import KursanzeigeKit
import SwiftUI

/// „Kurse“: which instruments each group shows. Usually a helper sets
/// them, so this card is the last one. It has the group buttons, the list
/// with an „Entfernen“ button per row, the fields to add a ticker, and
/// „Zurücksetzen“ with a confirmation.
struct InstrumentsCard: View {
    let viewModel: MainViewModel

    @State private var selectedGroup: MarketGroup
    @State private var newName = ""
    @State private var newSymbol = ""
    @State private var showingResetConfirmation = false

    init(viewModel: MainViewModel) {
        self.viewModel = viewModel
        _selectedGroup = State(initialValue: viewModel.selectedGroup)
    }

    var body: some View {
        SettingsCard(title: "Kurse") {
            HStack(alignment: .firstTextBaseline) {
                Text("Welche Titel jede Gruppe zeigt. Meist richtet das eine Hilfsperson ein.")
                    .font(Theme.settingsHintFont)
                    .foregroundStyle(Theme.mutedText)
                Spacer(minLength: Theme.settingsGap)
                resetButton
            }
            GroupSelectorView(selected: selectedGroup) { selectedGroup = $0 }
            instrumentList
            addFields
        }
    }

    private var instrumentList: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.constituents(in: selectedGroup)) { instrument in
                HStack(spacing: Theme.settingsGap) {
                    Text(instrument.name)
                        .font(Theme.settingsTextFont)
                        .foregroundStyle(Theme.text)
                    Spacer(minLength: 0)
                    Text(instrument.symbol)
                        .font(Theme.settingsHintFont)
                        .foregroundStyle(Theme.mutedText)
                    removeButton(instrument)
                }
                .padding(.vertical, Theme.settingsListRowPadding)
                Rectangle()
                    .fill(Theme.separator)
                    .frame(height: Theme.settingsListLineWidth)
            }
        }
    }

    private func removeButton(_ instrument: Instrument) -> some View {
        Button {
            viewModel.removeConstituent(symbol: instrument.symbol, from: selectedGroup)
        } label: {
            Label("Entfernen", systemImage: "trash")
                .font(Theme.settingsHintFont)
                .padding(.horizontal, Theme.settingsSmallButtonPadding)
                .frame(minHeight: Theme.settingsSmallButtonHeight)
        }
        .buttonStyle(ControlButtonStyle(look: .outlined))
        .accessibilityLabel("\(instrument.name) entfernen")
    }

    private var addFields: some View {
        VStack(spacing: Theme.settingsButtonSpacing) {
            inputField("Name", text: $newName)
            inputField("Ticker", text: $newSymbol)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
            Button {
                // A refused entry stays in the fields, so it can be corrected.
                guard viewModel.addConstituent(name: newName, symbol: newSymbol, to: selectedGroup) else { return }
                newName = ""
                newSymbol = ""
            } label: {
                SettingsButtonLabel(text: "Hinzufügen")
                    .background(canAdd ? Theme.action : Theme.headerBackground)
                    .foregroundStyle(canAdd ? Theme.buttonText : Theme.disabledButtonForeground)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
            }
            .buttonStyle(.plain)
            .disabled(!canAdd)
        }
    }

    private func inputField(_ title: String, text: Binding<String>) -> some View {
        TextField(title, text: text)
            .font(Theme.settingsTextFont)
            .padding(.horizontal, Theme.settingsFieldPadding)
            .frame(minHeight: Theme.settingsFieldHeight)
            .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadius).stroke(Theme.buttonBorder, lineWidth: Theme.buttonBorderWidth))
    }

    /// The confirmation is anchored on the button: on iPadOS it shows as a
    /// popover at the view that has the modifier.
    private var resetButton: some View {
        Button("Zurücksetzen") {
            showingResetConfirmation = true
        }
        .font(Theme.settingsHintFont)
        .foregroundStyle(Theme.negative)
        .confirmationDialog("Alle Listen zurücksetzen?", isPresented: $showingResetConfirmation, titleVisibility: .visible) {
            Button("Zurücksetzen", role: .destructive) {
                viewModel.resetConstituentsToDefaults()
            }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Eigene Änderungen an den Listen werden gelöscht und durch die Standardliste ersetzt.")
        }
    }

    private var canAdd: Bool {
        !newName.trimmingCharacters(in: .whitespaces).isEmpty && !newSymbol.trimmingCharacters(in: .whitespaces).isEmpty
    }
}
