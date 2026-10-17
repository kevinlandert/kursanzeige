import Foundation

/// The time of the last refresh, under the title „Kurse“. The texts are
/// the same as in Schlagzeilen. They always give the full date, so old
/// prices never look new. They have no „am“ and „um“, to save space.
/// The times are in Zurich.
public enum UpdateTexts {
    public static let missingUpdate = "Noch nicht aktualisiert"

    private static let zurich = TimeZone(identifier: "Europe/Zurich") ?? .current
    private static let locale = Locale(identifier: "de_CH")
    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zurich
        return calendar
    }()

    /// „Aktualisiert Freitag 16.10.26 14:27“.
    public static func updateLine(lastUpdate: Date?) -> String {
        guard let lastUpdate else { return missingUpdate }
        let style = Date.VerbatimFormatStyle(
            format: """
                Aktualisiert \(weekday: .wide) \(day: .twoDigits).\(month: .twoDigits).\(year: .twoDigits) \
                \(hour: .twoDigits(clock: .twentyFourHour, hourCycle: .zeroBased)):\(minute: .twoDigits)
                """,
            locale: locale, timeZone: zurich, calendar: calendar
        )
        return lastUpdate.formatted(style)
    }

    /// „Aktualisiert Freitag, 16. Oktober, 14 Uhr 27“ for VoiceOver.
    /// VoiceOver reads „16.10.26“ as three numbers. A full hour has no
    /// minutes: „9 Uhr“.
    public static func updateLabel(lastUpdate: Date?) -> String {
        guard let lastUpdate else { return missingUpdate }
        let style = Date.VerbatimFormatStyle(
            format: "Aktualisiert \(weekday: .wide), \(day: .defaultDigits). \(month: .wide), ",
            locale: locale, timeZone: zurich, calendar: calendar
        )
        let time = calendar.dateComponents([.hour, .minute], from: lastUpdate)
        let hour = time.hour ?? 0
        let minute = time.minute ?? 0
        let spokenTime = minute == 0 ? "\(hour) Uhr" : "\(hour) Uhr \(minute)"
        return lastUpdate.formatted(style) + spokenTime
    }
}
