/// The values of the lock screen and the Control Center for the page that
/// the user sees.
public struct NowPlayingItem: Sendable, Hashable {
    /// The name of the instrument in the cursor row.
    public let title: String
    /// The name of the group, e.g. „Schweiz“. The lock screen shows it as the artist.
    public let listName: String
    /// True while Vorlesen runs. The lock screen then shows Pause.
    public let isReading: Bool

    public init(title: String, listName: String, isReading: Bool) {
        self.title = title
        self.listName = listName
        self.isReading = isReading
    }
}
