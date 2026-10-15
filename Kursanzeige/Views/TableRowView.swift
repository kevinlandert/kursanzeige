import SwiftUI
import KursanzeigeKit

/// One row: name plus the four numeric columns, each colored by sign. Row
/// height comes from the parent (see `Theme.minRowHeight` and
/// `PerformanceTableView`); this view just fills whatever height it's given,
/// vertically centering every cell -- including a two-line-wrapped name --
/// via the enclosing `HStack`'s default alignment.
struct TableRowView: View {
    let row: InstrumentRow
    let oneYearMode: OneYearMode
    let rangeMode: RangeMode

    var body: some View {
        HStack(spacing: 0) {
            Text(row.instrument.name)
                .font(Theme.nameFont)
                .foregroundStyle(Color.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                // No `minimumScaleFactor`: every name stays at `nameFont`'s
                // size. Wraps at word boundaries same as any `Text`, and (per
                // standard Unicode line-breaking) a hyphen inside a single
                // word -- e.g. "Mercedes-Benz" -- is itself a legal break
                // point, so a too-long single word breaks there rather than
                // wrapping other names mid-character.
                .frame(width: layoutWidth(.name), alignment: .leading)

            ColumnDivider()
            valueCell(Formatting.price(row.price, group: row.instrument.group), color: Theme.neutral, width: layoutWidth(.price))
            ColumnDivider()
            valueCell(Formatting.percent(row.dayChangePercent), color: Formatting.dayChangeColor(percent: row.dayChangePercent, asOf: row.asOf), width: layoutWidth(.day))
            ColumnDivider()
            valueCell(Formatting.percent(rangeValue), color: Formatting.color(for: rangeValue), width: layoutWidth(.threeMonth))
            ColumnDivider()
            valueCell(Formatting.percent(oneYearValue), color: Formatting.color(for: oneYearValue), width: layoutWidth(.oneYear))
        }
        .padding(.horizontal, Theme.rowInset)
        .frame(maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }

    // Set by the parent via `.environment` in `PerformanceTableView`.
    @Environment(\.columnLayout) private var columnLayout
    private func layoutWidth(_ column: SortColumn) -> CGFloat {
        columnLayout.width(for: column)
    }

    private var oneYearValue: Double? {
        oneYearMode == .trailing ? row.oneYearChangePercent : row.yearToDateChangePercent
    }

    private var rangeValue: Double? {
        rangeMode == .oneMonth ? row.oneMonthChangePercent : row.threeMonthChangePercent
    }

    private func valueCell(_ text: String, color: Color, width: CGFloat) -> some View {
        signedText(text)
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .frame(width: width, alignment: .center)
    }

    /// Splits off a leading "+" / "\u{2212}" so it renders in `Theme.signFont`
    /// (bigger, heavier) while the digits stay in `Theme.valueFont`.
    private func signedText(_ text: String) -> Text {
        guard let first = text.first, first == "+" || first == "\u{2212}" else {
            return Text(text).font(Theme.valueFont)
        }
        return Text(String(first)).font(Theme.signFont) + Text(text.dropFirst()).font(Theme.valueFont)
    }
}

private struct ColumnLayoutKey: EnvironmentKey {
    static let defaultValue = ColumnLayout(totalWidth: 1000)
}

extension EnvironmentValues {
    var columnLayout: ColumnLayout {
        get { self[ColumnLayoutKey.self] }
        set { self[ColumnLayoutKey.self] = newValue }
    }
}
