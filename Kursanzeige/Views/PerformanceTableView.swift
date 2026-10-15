import SwiftUI
import KursanzeigeKit

/// The scrollable price table with a pinned, tappable header. Row height is
/// (available height − header) / 8 -- so a group with up to 8 constituents
/// fills the screen with no scrolling and one with 20 scrolls, the same
/// layout serving both without a special case -- floored at
/// `Theme.minRowHeight` so a two-line wrapped name is never clipped on a
/// small screen or a long list. Rows alternate white/`rowBackgroundOdd`
/// bands (rather than a horizontal rule after each one) so the eye can
/// follow a row across all five columns. Tapping anywhere on a row (not
/// just its name) calls `onSelect` with that row, for the chart
/// overlay.
struct PerformanceTableView: View {
    let rows: [InstrumentRow]
    let sortColumn: SortColumn
    let sortAscending: Bool
    let oneYearMode: OneYearMode
    let rangeMode: RangeMode
    let onSort: (SortColumn) -> Void
    let onSelect: (InstrumentRow) -> Void

    var body: some View {
        GeometryReader { geometry in
            // 5 columns means 4 dividers between them; subtract their width
            // up front so the columns' own widths still sum to the space
            // actually available for text.
            let dividerCount = 4
            let usableWidth = geometry.size.width - Theme.rowInset * 2 - Theme.columnDividerWidth * CGFloat(dividerCount)
            let layout = ColumnLayout(totalWidth: usableWidth)
            let rowHeight = max(Theme.minRowHeight, (geometry.size.height - Theme.headerHeight) / 8)

            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    Section {
                        ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                            TableRowView(row: row, oneYearMode: oneYearMode, rangeMode: rangeMode)
                                .frame(height: rowHeight)
                                .background(index.isMultiple(of: 2) ? Theme.rowBackgroundEven : Theme.rowBackgroundOdd)
                                .contentShape(Rectangle())
                                .onTapGesture { onSelect(row) }
                                .accessibilityAddTraits(.isButton)
                                .accessibilityHint("Zeigt den Jahresverlauf")
                                .accessibilityIdentifier("tableRow")
                        }
                    } header: {
                        TableHeaderView(layout: layout, sortColumn: sortColumn, sortAscending: sortAscending, oneYearMode: oneYearMode, rangeMode: rangeMode, onTap: onSort)
                            .frame(height: Theme.headerHeight)
                    }
                }
                .environment(\.columnLayout, layout)
            }
            .background(Theme.background)
        }
    }
}
