import Observation

/// The on and off switch of "Vorlesen" on the chart page. When on, it
/// reads each new chart text: after a step to an other row, a change of
/// range, or the arrival of a fetched history. A new text stops the old
/// one. The chart page makes a new reader each time it opens, so the
/// reader starts off.
@Observable
@MainActor
public final class ChartReader {
    public private(set) var isOn = false

    private let speaker: Speaking

    public init(speaker: Speaking) {
        self.speaker = speaker
    }

    /// The tap on the button. On reads `shownText` at once. Off stops the
    /// voice. A `nil` text means no closes yet: `readIfOn` reads the text
    /// when the closes arrive.
    public func toggle(shownText: String?) {
        if isOn {
            turnOff()
        } else {
            isOn = true
            replaceText(with: shownText)
        }
    }

    /// A new chart text. Has an effect only when the reader is on.
    public func readIfOn(_ text: String?) {
        guard isOn else { return }
        replaceText(with: text)
    }

    /// Stops the voice and turns the reader off, e.g. when the chart page
    /// closes.
    public func turnOff() {
        isOn = false
        speaker.stop()
    }

    /// Stops the old text also when the new chart has no text yet.
    /// Otherwise the voice tells the old chart while the screen shows the
    /// new one.
    private func replaceText(with text: String?) {
        speaker.stop()
        if let text {
            speaker.speak(text)
        }
    }
}
