/// The names of the bottom buttons and their hints for VoiceOver, as in
/// Schlagzeilen. VoiceOver reads a hint after a short wait, so a hint
/// tells what the button does.
public enum ControlTexts {
    public static let previous = "Vorherige"
    public static let startReading = "Vorlesen"
    public static let pause = "Pause"
    public static let next = "Nächste"
    public static let open = "Öffnen"
    public static let close = "Schliessen"

    public static let previousHint = "Wählt die Zeile davor und liest sie vor."
    public static let startReadingHint = "Liest ab der ausgewählten Zeile vor."
    public static let pauseHint = "Hält das Vorlesen an."
    public static let nextHint = "Wählt die nächste Zeile und liest sie vor."
    public static let openHint = "Zeigt den Verlauf der ausgewählten Zeile."
    public static let closeHint = "Zeigt wieder die Tabelle."

    /// A row of the table. A tap opens the chart at once.
    public static let tableRowHint = "Zeigt den Verlauf dieser Zeile."
    /// Vorherige and Nächste on the chart page.
    public static let previousChartHint = "Zeigt den Verlauf der Zeile davor und liest ihn vor."
    public static let nextChartHint = "Zeigt den Verlauf der nächsten Zeile und liest ihn vor."
}
