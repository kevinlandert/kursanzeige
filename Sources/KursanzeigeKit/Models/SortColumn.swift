import Foundation

/// The columns a table row can be sorted by, matching the visible columns
/// left to right: Name, Kurs, Tag, 3-Monate, 1-Jahr.
public enum SortColumn: String, CaseIterable, Sendable {
    case name = "Name"
    case price = "Kurs"
    case day = "Tag"
    case threeMonth = "3-Monate"
    case oneYear = "1-Jahr"
}

/// A column plus the direction it is currently sorted in.
struct SortState: Equatable {
    let column: SortColumn
    let ascending: Bool

    /// Tapping the same header again reverses direction; tapping a new
    /// header sorts by it ascending first.
    func toggled(for column: SortColumn) -> SortState {
        if column == self.column {
            return SortState(column: column, ascending: !ascending)
        }
        return SortState(column: column, ascending: true)
    }
}
