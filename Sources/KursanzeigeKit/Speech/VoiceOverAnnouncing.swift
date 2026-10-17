/// The VoiceOver state and its announcements. The app gives the iOS
/// accessibility notifications, a test gives a recorder.
///
/// While VoiceOver runs, VoiceOver speaks the messages of a list, so that
/// the two voices do not speak at the same time. The focus of VoiceOver
/// stays on the button, so without the announcement the user hears nothing.
@MainActor
public protocol VoiceOverAnnouncing: AnyObject {
    /// True while VoiceOver runs.
    var isRunning: Bool { get }

    /// Gives the text to VoiceOver. With the normal priority, VoiceOver
    /// stops its current text and reads this text, so that quick presses
    /// give only the last row. A high priority is not stopped by other speech.
    func announce(_ text: String, priority: AnnouncementPriority)
}

/// The priority of a VoiceOver announcement.
public enum AnnouncementPriority: Sendable {
    /// The next announcement or a focus change stops it.
    case normal
    /// Other speech does not stop it. For a message after a change of the
    /// group, where VoiceOver also reads the tapped button.
    case high
}
