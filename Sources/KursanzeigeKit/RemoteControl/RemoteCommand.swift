/// A command from outside the screen: the AirPods, the lock screen or
/// the Control Center. Play, pause and the toggle go to Vorlesen and
/// Pause, the tracks go to Nächste and Vorherige.
public enum RemoteCommand: Sendable, CaseIterable {
    case play
    case pause
    case togglePlayPause
    case nextTrack
    case previousTrack
}
