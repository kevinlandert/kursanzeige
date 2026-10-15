import SwiftUI

/// A vertical rule between two columns, in both the header and every row,
/// so adjacent numbers (Tag / 3-Mt. / 1-Jahr) don't run together.
struct ColumnDivider: View {
    var body: some View {
        Rectangle()
            .fill(Theme.separator)
            .frame(width: Theme.columnDividerWidth)
            .padding(.vertical, 10)
    }
}
