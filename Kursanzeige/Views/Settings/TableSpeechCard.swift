import KursanzeigeKit
import SwiftUI

/// „Tabelle und Vorlesen“: one row per table column, in the order of the
/// table. A row has the column name, a range choice where the column has
/// one, and a checkbox „Vorlesen“. The name is always read. The sample
/// below tells what the voice reads for the cursor row of the table.
struct TableSpeechCard: View {
    let appModel: AppModel
    @AppStorage(SpokenColumns.storageKey) private var spokenColumns = SpokenColumns.standard

    private var viewModel: MainViewModel { appModel.viewModel }

    var body: some View {
        SettingsCard(title: "Tabelle und Vorlesen") {
            Grid(alignment: .leading, horizontalSpacing: Theme.settingsGap, verticalSpacing: Theme.settingsButtonSpacing) {
                GridRow {
                    headText("Spalte")
                    headText("Zeitraum")
                    headText("Vorlesen")
                }
                nameRow
                columnRow("Kurs", spokenName: "Kurs", column: .price, identifier: "price") { noRange }
                columnRow("Tag", spokenName: "Tag", column: .day, identifier: "day") { noRange }
                columnRow(viewModel.rangeMode.headerTitle, spokenName: viewModel.rangeMode.spokenName, column: .shortRange, identifier: "shortRange") {
                    shortRangeChoice
                }
                columnRow(viewModel.oneYearMode.headerTitle, spokenName: viewModel.oneYearMode.spokenName, column: .longRange, identifier: "longRange") {
                    longRangeChoice
                }
            }
            sample
        }
    }

    private func headText(_ text: String) -> some View {
        Text(text)
            .font(Theme.settingsHintFont)
            .foregroundStyle(Theme.mutedText)
            .accessibilityHidden(true)
    }

    /// The name is always read, so its checkbox is grey and always on.
    private var nameRow: some View {
        GridRow {
            columnName("Name")
            noRange
            Toggle(isOn: .constant(true)) { checkboxText("immer") }
                .toggleStyle(CheckboxToggleStyle())
                .disabled(true)
                .accessibilityLabel("Name wird immer vorgelesen")
        }
    }

    /// - Parameters:
    ///   - spokenName: the name for VoiceOver. The voice does not read
    ///     „1-Mt.“ and „YTD“ well.
    ///   - identifier: stays the same when the range changes, for UI tests.
    private func columnRow<Range: View>(
        _ name: String, spokenName: String, column: SpokenColumns, identifier: String, @ViewBuilder range: () -> Range
    ) -> some View {
        GridRow {
            columnName(name)
            range()
            Toggle(isOn: readBinding(column)) { checkboxText(spokenColumns.contains(column) ? "Ein" : "Aus") }
                .toggleStyle(CheckboxToggleStyle())
                .accessibilityLabel("\(spokenName) vorlesen")
                .accessibilityIdentifier("readColumn.\(identifier)")
        }
    }

    private func columnName(_ name: String) -> some View {
        Text(name)
            .font(Theme.settingsTextFont)
            .foregroundStyle(Theme.text)
            .accessibilityHidden(true)
    }

    private func checkboxText(_ text: String) -> some View {
        Text(text)
            .font(Theme.settingsTextFont)
            .foregroundStyle(Theme.text)
    }

    /// A column without a range choice.
    private var noRange: some View {
        Text("–")
            .font(Theme.settingsTextFont)
            .foregroundStyle(Theme.mutedText)
            .accessibilityHidden(true)
    }

    private func readBinding(_ column: SpokenColumns) -> Binding<Bool> {
        Binding(
            get: { spokenColumns.contains(column) },
            set: { isOn in
                if isOn { spokenColumns.insert(column) } else { spokenColumns.remove(column) }
            }
        )
    }

    private var shortRangeChoice: some View {
        TwoOptionToggle(
            leftLabel: RangeMode.oneMonth.choiceTitle, leftSpokenLabel: RangeMode.oneMonth.spokenName, leftValue: RangeMode.oneMonth,
            rightLabel: RangeMode.threeMonth.choiceTitle, rightSpokenLabel: RangeMode.threeMonth.spokenName, rightValue: RangeMode.threeMonth,
            selection: viewModel.rangeMode, font: Theme.settingsButtonFont
        ) { newValue in
            guard newValue != viewModel.rangeMode else { return }
            viewModel.toggleRangeMode()
        }
    }

    private var longRangeChoice: some View {
        TwoOptionToggle(
            leftLabel: OneYearMode.trailing.choiceTitle, leftSpokenLabel: OneYearMode.trailing.spokenName, leftValue: OneYearMode.trailing,
            rightLabel: OneYearMode.yearToDate.choiceTitle, rightSpokenLabel: OneYearMode.yearToDate.spokenName, rightValue: OneYearMode.yearToDate,
            selection: viewModel.oneYearMode, font: Theme.settingsButtonFont
        ) { newValue in
            guard newValue != viewModel.oneYearMode else { return }
            viewModel.toggleOneYearMode()
        }
    }

    /// The text of the cursor row with the chosen columns.
    private var sample: some View {
        Text("So klingt eine Zeile: „\(appModel.table.sampleText)“")
            .font(Theme.settingsTextFont)
            .foregroundStyle(Theme.text)
            .fixedSize(horizontal: false, vertical: true)
            .padding(Theme.settingsCardSpacing)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.neutralFill, in: RoundedRectangle(cornerRadius: Theme.statusLineCornerRadius))
            .accessibilityIdentifier("speechSample")
    }
}
