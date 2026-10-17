import KursanzeigeKit
import MediaPlayer

/// Connects the commands of the AirPods, the lock screen and the Control
/// Center to `RemoteCommandRouter`. iOS gives the commands only to the app
/// that played audio last. The router gives each command to the page that
/// the person sees.
@MainActor
final class RemoteCommandHandler {
    init(router: RemoteCommandRouter) {
        let center = MPRemoteCommandCenter.shared()
        let systemCommands: [(MPRemoteCommand, RemoteCommand)] = [
            (center.playCommand, .play),
            (center.pauseCommand, .pause),
            (center.togglePlayPauseCommand, .togglePlayPause),
            (center.nextTrackCommand, .nextTrack),
            (center.previousTrackCommand, .previousTrack),
        ]
        for (systemCommand, command) in systemCommands {
            systemCommand.isEnabled = true
            systemCommand.addTarget { [weak router] _ in
                guard let router else { return .commandFailed }
                return Self.performCommand(command, with: router)
            }
        }
    }

    /// iOS calls the handlers on the main thread in practice, but does not
    /// promise it. On another thread, the command goes to the main actor
    /// later, and the answer is a success.
    private nonisolated static func performCommand(
        _ command: RemoteCommand,
        with router: RemoteCommandRouter
    ) -> MPRemoteCommandHandlerStatus {
        guard Thread.isMainThread else {
            Task { @MainActor in router.performCommand(command) }
            return .success
        }
        return MainActor.assumeIsolated {
            router.performCommand(command) ? .success : .noActionableNowPlayingItem
        }
    }
}
