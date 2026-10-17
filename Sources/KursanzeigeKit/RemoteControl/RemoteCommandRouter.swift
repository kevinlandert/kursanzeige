import Observation
import os

/// Gives each remote command to the list of the page that the user sees,
/// and gives the values of the lock screen for that page.
///
/// - On the table, the table list gets the commands.
/// - On the chart page, the chart list gets them.
/// - While the settings show, the commands do nothing. The table under
///   the settings must not read.
@Observable
@MainActor
public final class RemoteCommandRouter {
    private static let logger = Logger(subsystem: "com.kevinlandert.Kursanzeige", category: "RemoteControl")

    private let tableReader: ListReader
    private var page = VisiblePage.table

    public init(tableReader: ListReader) {
        self.tableReader = tableReader
    }

    /// The values of the lock screen. The settings show the values of the
    /// table under them.
    public var nowPlayingItem: NowPlayingItem {
        (findTarget() ?? tableReader).nowPlayingItem
    }

    public func showTable() {
        page = .table
    }

    public func showChart(_ chartReader: ListReader) {
        page = .chart(chartReader)
    }

    public func showSettings() {
        page = .settings
    }

    /// Does the command on the list of the visible page.
    /// - Returns: false when the page has no list.
    @discardableResult
    public func performCommand(_ command: RemoteCommand) -> Bool {
        guard let target = findTarget() else {
            Self.logger.info("The remote command \(String(describing: command), privacy: .public) has no target.")
            return false
        }
        switch command {
        case .play: target.startReading()
        case .pause: target.pauseReading()
        case .togglePlayPause: target.toggleReading()
        // The screen can be off, so a step reads the new row.
        case .nextTrack: target.showNext(readsRow: true)
        case .previousTrack: target.showPrevious(readsRow: true)
        }
        return true
    }

    private func findTarget() -> ListReader? {
        switch page {
        case .table: tableReader
        case .chart(let chartReader): chartReader
        case .settings: nil
        }
    }
}

/// The page that the user sees.
private enum VisiblePage {
    case table
    case chart(ListReader)
    /// The settings have no list.
    case settings
}
