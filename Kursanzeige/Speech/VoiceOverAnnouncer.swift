import KursanzeigeKit
import SwiftUI
import UIKit

/// `VoiceOverAnnouncing` with the accessibility notifications of iOS.
@MainActor
final class VoiceOverAnnouncer: VoiceOverAnnouncing {
    var isRunning: Bool {
        UIAccessibility.isVoiceOverRunning
    }

    /// The normal priority is the default of iOS: the announcement stops the
    /// current text of VoiceOver. Thus quick presses of Nächste give only the last row.
    func announce(_ text: String, priority: AnnouncementPriority) {
        var announcement = AttributedString(text)
        if priority == .high {
            announcement.accessibilitySpeechAnnouncementPriority = .high
        }
        AccessibilityNotification.Announcement(announcement).post()
    }
}
