import SwiftUI
import KursanzeigeKit

/// The scrollable price table with a pinned, tappable header. Row height is
/// (available height − header) / 8 -- so a group with up to 8 constituents
/// fills the space with no scrolling and one with 20 scrolls, the same
/// layout serving both without a special case -- floored at
/// `Theme.minRowHeight` so a two-line wrapped name is never clipped on a
/// small screen or a long list. Rows alternate white/`rowBackgroundOdd`
/// bands (rather than a horizontal rule after each one) so the eye can
/// follow a row across all five columns. The cursor row is yellow, and
/// the table scrolls it into view after each move. A tap on a row calls
/// `onSelect` with that row, for the chart page.
struct PerformanceTableView: View {
    let rows: [InstrumentRow]
    /// The symbol of the cursor row.
    let cursorRowId: String?
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

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                        Section {
                            ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                                makeRow(row, index: index, height: rowHeight)
                            }
                        } header: {
                            TableHeaderView(layout: layout, sortColumn: sortColumn, sortAscending: sortAscending, oneYearMode: oneYearMode, rangeMode: rangeMode, onTap: onSort)
                                .frame(height: Theme.headerHeight)
                        }
                    }
                    .environment(\.columnLayout, layout)
                }
                .background(Theme.background)
                .onAppear { scrollToCursor(proxy, isAnimated: false) }
                .onChange(of: cursorRowId) { scrollToCursor(proxy, isAnimated: true) }
                // A turn of the iPad changes the row height.
                .onChange(of: geometry.size) { scrollToCursor(proxy, isAnimated: false) }
            }
        }
    }

    private func makeRow(_ row: InstrumentRow, index: Int, height: CGFloat) -> some View {
        let isCursor = row.id == cursorRowId
        return TableRowView(row: row, isCursor: isCursor, oneYearMode: oneYearMode, rangeMode: rangeMode)
            .frame(height: height)
            .background(rowBackground(index: index, isCursor: isCursor))
            .overlay {
                if isCursor {
                    Rectangle().strokeBorder(Theme.cursorBorder, lineWidth: Theme.cursorBorderWidth)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { onSelect(row) }
            .accessibilityAddTraits(isCursor ? [.isButton, .isSelected] : .isButton)
            .accessibilityHint(ControlTexts.tableRowHint)
            .accessibilityIdentifier("tableRow")
            .id(row.id)
    }

    private func rowBackground(index: Int, isCursor: Bool) -> Color {
        if isCursor { return Theme.cursor }
        return index.isMultiple(of: 2) ? Theme.rowBackgroundEven : Theme.rowBackgroundOdd
    }

    /// Without an anchor, the scroll view moves the least distance that
    /// shows the full row.
    private func scrollToCursor(_ proxy: ScrollViewProxy, isAnimated: Bool) {
        guard let cursorRowId else { return }
        withAnimation(isAnimated ? .default : nil) {
            proxy.scrollTo(cursorRowId)
        }
    }
}
