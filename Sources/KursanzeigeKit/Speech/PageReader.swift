import Observation

/// The on and off switch of "Vorlesen" on a page. When on, it reads each
/// new text of the page: on the chart page after a step to an other
/// row, a change of range, or a fetched history. On the main page after
/// a change of group. A new text stops the old one. Each page has its
/// own reader, and a new reader starts off.
@Observable
@MainActor
public final class PageReader {
    public private(set) var isOn = false

    private let speaker: Speaking

    public init(speaker: Speaking) {
        self.speaker = speaker
    }

    /// The tap on the button. On reads `shownText` at once. Off stops the
    /// voice. A `nil` text means no data yet: `readIfOn` reads the text
    /// when the data arrives.
    public func toggle(shownText: String?) {
        if isOn {
            turnOff()
        } else {
            isOn = true
            replaceText(with: shownText)
        }
    }

    /// A new text of the page. Has an effect only when the reader is on.
    public func readIfOn(_ text: String?) {
        guard isOn else { return }
        replaceText(with: text)
    }

    /// Stops the voice and turns the reader off, e.g. when the page
    /// closes.
    public func turnOff() {
        isOn = false
        speaker.stop()
    }

    /// Stops the old text also when the new text is not there yet.
    /// Otherwise the voice tells the old page while the screen shows the
    /// new one.
    private func replaceText(with text: String?) {
        speaker.stop()
        if let text {
            speaker.speak(text)
        }
    }
}
