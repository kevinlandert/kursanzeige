import AVFoundation
import os

/// Stops all speech when iOS takes the audio away or the headphones go
/// away, as Apple recommends for audio apps.
///
/// - An interruption, for example a call or Siri, ends Vorlesen. The voice
///   does not start again at the end of the interruption. The person starts
///   it with Vorlesen or the play command of the AirPods.
/// - When the old output goes away, for example AirPods out of the ears,
///   the voice must not go on with the speaker of the iPad.
/// - A stop of the voice alone does not end the pause between rows. Thus
///   the lists end Vorlesen themselves.
@MainActor
final class AudioSessionObserver {
    private static let logger = Logger(subsystem: "com.kevinlandert.Kursanzeige", category: "Speech")
    /// The notification center keeps the observers. The app keeps this object for its full life.
    private let observers: [any NSObjectProtocol]

    /// - Parameter stopSpeech: ends Vorlesen and stops the voice.
    init(stopSpeech: @escaping @MainActor () -> Void) {
        let center = NotificationCenter.default
        let session = AVAudioSession.sharedInstance()
        let logger = Self.logger
        let interruptionObserver = center.addObserver(
            forName: AVAudioSession.interruptionNotification, object: session, queue: .main
        ) { notification in
            guard notification.isInterruptionStart else { return }
            logger.info("iOS interrupted the audio. Vorlesen stops.")
            MainActor.assumeIsolated { stopSpeech() }
        }
        let routeObserver = center.addObserver(
            forName: AVAudioSession.routeChangeNotification, object: session, queue: .main
        ) { notification in
            guard notification.isOldOutputRemoval else { return }
            logger.info("The audio output went away. Vorlesen stops.")
            MainActor.assumeIsolated { stopSpeech() }
        }
        observers = [interruptionObserver, routeObserver]
    }
}

private extension Notification {
    /// True for an interruption of the audio session that starts. iOS
    /// then ended the session of the app.
    var isInterruptionStart: Bool {
        guard let rawType = userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt else { return false }
        return AVAudioSession.InterruptionType(rawValue: rawType) == .began
    }

    /// True for a route change after the old output went away, for example
    /// headphones that the person took out.
    var isOldOutputRemoval: Bool {
        guard let rawReason = userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt else { return false }
        return AVAudioSession.RouteChangeReason(rawValue: rawReason) == .oldDeviceUnavailable
    }
}
