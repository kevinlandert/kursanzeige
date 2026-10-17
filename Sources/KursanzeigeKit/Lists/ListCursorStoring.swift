import Foundation

/// Keeps the cursor row of each list, so that each group shows its last
/// row again, also after a new start of the app.
@MainActor
public protocol ListCursorStoring: AnyObject {
    /// The id of the saved cursor row of `list`. Nil without a saved row.
    func loadCursorRowId(list: String) -> String?
    func saveCursorRowId(_ rowId: String, list: String)
}

/// Keeps the cursors in the user defaults of the app.
@MainActor
public final class UserDefaultsCursorStore: ListCursorStoring {
    private static let keyPrefix = "cursorRowId."
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func loadCursorRowId(list: String) -> String? {
        defaults.string(forKey: Self.keyPrefix + list)
    }

    public func saveCursorRowId(_ rowId: String, list: String) {
        defaults.set(rowId, forKey: Self.keyPrefix + list)
    }
}

/// A cursor store that keeps nothing. The chart page uses it: it opens on
/// the tapped row, and it must not change the saved cursor of the table.
@MainActor
final class UnsavedCursorStore: ListCursorStoring {
    func loadCursorRowId(list: String) -> String? {
        nil
    }

    func saveCursorRowId(_ rowId: String, list: String) {}
}
