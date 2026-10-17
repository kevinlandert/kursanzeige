import SwiftUI

/// Puts its views side by side in columns of the same width and gives
/// each view the height of the tallest view. Without a proposed width, the layout
/// wants each column as wide as the widest view. Thus `ViewThatFits`
/// knows when one label does not fit into its column.
struct EqualColumnsLayout: Layout {
    let spacing: Double

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard !subviews.isEmpty else { return .zero }
        // The height is the ideal height, so a view with an infinite maximum
        // height does not take all of the screen.
        let columnProposal = ProposedViewSize(
            width: proposal.width.map { findColumnWidth(totalWidth: $0, columnCount: subviews.count) },
            height: nil
        )
        let sizes = subviews.map { $0.sizeThatFits(columnProposal) }
        let widestColumn = sizes.map(\.width).max() ?? 0
        let idealWidth = widestColumn * CGFloat(subviews.count) + findTotalSpacing(columnCount: subviews.count)
        return CGSize(width: proposal.width ?? idealWidth, height: sizes.map(\.height).max() ?? 0)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let columnWidth = findColumnWidth(totalWidth: bounds.width, columnCount: subviews.count)
        let columnProposal = ProposedViewSize(width: columnWidth, height: bounds.height)
        for (index, subview) in subviews.enumerated() {
            let x = bounds.minX + CGFloat(index) * (columnWidth + spacing)
            subview.place(at: CGPoint(x: x, y: bounds.minY), anchor: .topLeading, proposal: columnProposal)
        }
    }

    private func findColumnWidth(totalWidth: CGFloat, columnCount: Int) -> CGFloat {
        max(0, (totalWidth - findTotalSpacing(columnCount: columnCount)) / CGFloat(columnCount))
    }

    private func findTotalSpacing(columnCount: Int) -> CGFloat {
        spacing * CGFloat(max(0, columnCount - 1))
    }
}
