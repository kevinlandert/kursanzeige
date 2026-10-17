import KursanzeigeKit
import MediaPlayer
import Observation

/// Shows the cursor row of the visible page on the lock screen and in the
/// Control Center, and follows each change of it.
///
/// The values stay also when Vorlesen pauses, with the rate 0. Then the
/// lock screen shows the play button, and the AirPods can start Vorlesen
/// again. Without values, the lock screen would hide the controls.
@MainActor
final class NowPlayingPublisher {
    private let router: RemoteCommandRouter
    private var shownItem: NowPlayingItem?

    init(router: RemoteCommandRouter) {
        self.router = router
        followNowPlayingItem()
    }

    /// Shows the item now, and again after each change of the values that it reads.
    private func followNowPlayingItem() {
        let item = withObservationTracking {
            router.nowPlayingItem
        } onChange: { [weak self] in
            Task { @MainActor in self?.followNowPlayingItem() }
        }
        showItem(item)
    }

    private func showItem(_ item: NowPlayingItem) {
        guard item != shownItem else { return }
        shownItem = item
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: item.title,
            MPMediaItemPropertyArtist: item.listName,
            MPNowPlayingInfoPropertyMediaType: MPNowPlayingInfoMediaType.audio.rawValue,
            MPNowPlayingInfoPropertyPlaybackRate: item.isReading ? 1.0 : 0.0,
        ]
    }
}
