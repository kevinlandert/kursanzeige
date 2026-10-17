import SwiftUI
import KursanzeigeKit

/// Pinned column header. Tapping any column sorts by it; the active column
/// shows a bold arrow so the current sort is visible without guessing.
struct TableHeaderView: View {
    let layout: ColumnLayout
    let sortColumn: SortColumn
    let sortAscending: Bool
    let oneYearMode: OneYearMode
    let rangeMode: RangeMode
    let onTap: (SortColumn) -> Void

    var body: some View {
        HStack(spacing: 0) {
            // Over the number badges of the rows.
            Color.clear.frame(width: Theme.numberColumnWidth)
            headerCell("Name", column: .name, width: layout.name)
            ColumnDivider()
            headerCell("Kurs", column: .price, width: layout.price)
            ColumnDivider()
            headerCell("Tag", column: .day, width: layout.day)
            ColumnDivider()
            headerCell(rangeMode == .oneMonth ? "1-Mt." : "3-Mt.", column: .threeMonth, width: layout.threeMonth)
            ColumnDivider()
            headerCell(oneYearMode == .trailing ? "1-Jahr" : "YTD", column: .oneYear, width: layout.oneYear)
        }
        .padding(.horizontal, Theme.rowInset)
        .padding(.vertical, Theme.rowVerticalPadding)
        .background(Theme.headerBackground)
    }

    /// Headers are centered over their column regardless of how that
    /// column's values align (numbers stay right-aligned below) -- reads
    /// more balanced now that dividers make each column its own box.
    private func headerCell(_ title: String, column: SortColumn, width: CGFloat) -> some View {
        Button {
            onTap(column)
        } label: {
            HStack(spacing: 4) {
                Text(title)
                    .font(Theme.headerFont)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if sortColumn == column {
                    Image(systemName: sortAscending ? "chevron.up" : "chevron.down")
                        .font(.system(size: 16, weight: .bold))
                }
            }
            .foregroundStyle(sortColumn == column ? Theme.accentText : Theme.text)
        }
        .buttonStyle(.plain)
        .frame(width: width, alignment: .center)
        .accessibilityHint(sortColumn == column ? "Sortiert" : "Zum Sortieren antippen")
    }
}
