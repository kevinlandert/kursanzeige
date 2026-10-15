import SwiftUI
import KursanzeigeKit

/// Settings sheet: the two rarely-changed display-mode toggles up top, then
/// per-group list customization below. A native `List` throughout so
/// section headers, the segmented pickers, and swipe-to-delete all come
/// from the platform instead of being hand-rolled -- but every font here is
/// blown up well past the List/Picker defaults, and the sheet is forced to
/// (near-)full screen, to match the rest of this app: it's built for
/// someone with low vision, and a settings screen is no exception just
/// because it's opened rarely.
struct SettingsView: View {
    let viewModel: MainViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedEditGroup: MarketGroup
    @State private var newName = ""
    @State private var newSymbol = ""
    @State private var showingResetConfirmation = false

    private static let sectionHeaderFont = Font.system(size: 24, weight: .bold)
    /// Same size as the constituent name in the list below -- explicitly
    /// requested, so the Anzeige toggles read as the same visual weight as
    /// everything else on this screen.
    private static let rowNameFont = Font.system(size: 26, weight: .medium)
    private static let rowSymbolFont = Font.system(size: 22)
    private static let fieldFont = Font.system(size: 26)

    init(viewModel: MainViewModel) {
        self.viewModel = viewModel
        _selectedEditGroup = State(initialValue: viewModel.selectedGroup)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TwoOptionToggle(
                        leftLabel: "1 Monat", leftValue: RangeMode.oneMonth,
                        rightLabel: "3 Monate", rightValue: RangeMode.threeMonth,
                        selection: viewModel.rangeMode, font: Self.rowNameFont
                    ) { newValue in
                        guard newValue != viewModel.rangeMode else { return }
                        viewModel.toggleRangeMode()
                    }
                    .listRowInsets(EdgeInsets())
                    .padding(.horizontal, Theme.rowInset)
                    .padding(.vertical, 6)

                    TwoOptionToggle(
                        leftLabel: "1 Jahr", leftValue: OneYearMode.trailing,
                        rightLabel: "YTD", rightValue: OneYearMode.yearToDate,
                        selection: viewModel.oneYearMode, font: Self.rowNameFont
                    ) { newValue in
                        guard newValue != viewModel.oneYearMode else { return }
                        viewModel.toggleOneYearMode()
                    }
                    .listRowInsets(EdgeInsets())
                    .padding(.horizontal, Theme.rowInset)
                    .padding(.vertical, 6)
                } header: {
                    Text("Anzeige").font(Self.sectionHeaderFont).foregroundStyle(Color.primary).textCase(nil)
                }

                Section {
                    GroupSelectorView(selected: selectedEditGroup) { selectedEditGroup = $0 }
                        .listRowInsets(EdgeInsets())
                        .padding(.horizontal, Theme.rowInset)
                        .padding(.vertical, 6)
                } header: {
                    HStack {
                        Text("Gruppe").font(Self.sectionHeaderFont).foregroundStyle(Color.primary)
                        Spacer()
                        Button("Zurücksetzen") {
                            showingResetConfirmation = true
                        }
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Theme.negative)
                        // Anchored here, on the button itself, rather than on the
                        // enclosing List: on iPadOS `confirmationDialog` presents
                        // as a popover anchored to whatever view the modifier is
                        // attached to. Attached to the full-screen List, the
                        // popover was anchoring to that view's frame instead of
                        // this button -- landing pinned near the top of the
                        // screen, detached from where it was triggered, with its
                        // actual hit-test region not lining up with what was
                        // drawn (so taps missed). iPhone was unaffected because
                        // confirmationDialog always renders as a bottom sheet
                        // there regardless of anchor.
                        .confirmationDialog(
                            "Alle Listen zurücksetzen?",
                            isPresented: $showingResetConfirmation,
                            titleVisibility: .visible
                        ) {
                            Button("Zurücksetzen", role: .destructive) {
                                viewModel.resetConstituentsToDefaults()
                            }
                            Button("Abbrechen", role: .cancel) {}
                        } message: {
                            Text("Eigene Änderungen an den Listen werden gelöscht und durch die Standardliste ersetzt.")
                        }
                    }
                    .textCase(nil)
                }

                Section {
                    ForEach(viewModel.constituents(in: selectedEditGroup)) { instrument in
                        HStack {
                            Text(instrument.name)
                                .font(Self.rowNameFont)
                            Spacer()
                            Text(instrument.symbol)
                                .font(Self.rowSymbolFont)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 5)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                viewModel.removeConstituent(symbol: instrument.symbol, from: selectedEditGroup)
                            } label: {
                                Label("Entfernen", systemImage: "trash")
                            }
                            .font(Self.rowSymbolFont)
                        }
                    }
                } header: {
                    Text(selectedEditGroup.displayName).font(Self.sectionHeaderFont).foregroundStyle(Color.primary).textCase(nil)
                }

                Section {
                    TextField("Name", text: $newName)
                        .font(Self.fieldFont)
                        .padding(.vertical, 8)
                    TextField("Ticker", text: $newSymbol)
                        .font(Self.fieldFont)
                        .padding(.vertical, 8)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()

                    Button {
                        viewModel.addConstituent(name: newName, symbol: newSymbol, to: selectedEditGroup)
                        newName = ""
                        newSymbol = ""
                    } label: {
                        Text("Hinzufügen")
                            .font(Theme.groupButtonFont)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(canAdd ? Theme.positive : Theme.headerBackground)
                            .foregroundStyle(canAdd ? Color.white : Color.secondary)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
                    }
                    .buttonStyle(.plain)
                    .disabled(!canAdd)
                    .listRowInsets(EdgeInsets())
                    .padding(.horizontal, Theme.rowInset)
                    .padding(.vertical, 10)
                } header: {
                    Text("Hinzufügen").font(Self.sectionHeaderFont).foregroundStyle(Color.primary).textCase(nil)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // A custom principal item instead of the system large title,
                // so the title and the close button sit in the same row at
                // the same height -- the large-title layout put them in two
                // different rows, which read as misaligned.
                ToolbarItem(placement: .principal) {
                    Text("Einstellungen")
                        .font(.system(size: 32, weight: .bold))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("Einstellungen schliessen")
                }
            }
        }
    }

    private var canAdd: Bool {
        !newName.trimmingCharacters(in: .whitespaces).isEmpty && !newSymbol.trimmingCharacters(in: .whitespaces).isEmpty
    }
}

#Preview {
    SettingsView(viewModel: MainViewModel())
}
