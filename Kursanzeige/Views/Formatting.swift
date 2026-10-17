import SwiftUI
import KursanzeigeKit

/// Display formatting for table cells. Kept out of KursanzeigeKit because
/// it's presentation, not domain logic -- `InstrumentRow` stays plain
/// numbers, and only the view layer decides how those numbers look.
enum Formatting {
    private static let swissLocale = Locale(identifier: "de_CH")
    private static let zurichCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Zurich") ?? .current
        return calendar
    }()

    /// The decimals follow `PricePrecision`, the same rule as the spoken
    /// price. "Up to": 999.5 prints as that, not as 999.50.
    static func price(_ value: Double?, group: MarketGroup) -> String {
        guard let value else { return "–" }
        let maxDecimals = PricePrecision.maximumFractionDigits(for: value, group: group)
        return value.formatted(.number.locale(swissLocale).precision(.fractionLength(0...maxDecimals)).grouping(.automatic))
    }

    /// Always signed, one decimal, with a true minus sign (U+2212) rather
    /// than a hyphen -- reads unambiguously at very large sizes.
    static func percent(_ value: Double?) -> String {
        guard let value else { return "–" }
        let sign = value < 0 ? "\u{2212}" : "+"
        let magnitude = abs(value).formatted(.number.locale(swissLocale).precision(.fractionLength(1)))
        return "\(sign)\(magnitude) %"
    }

    static func color(for value: Double?) -> Color {
        tone(for: value).color
    }

    /// Plus, minus or neutral by the sign of the value.
    static func tone(for value: Double?) -> ValueTone {
        guard let value else { return .neutral }
        if value > 0 { return .positive }
        if value < 0 { return .negative }
        return .neutral
    }

    /// The tone of the "Tag" cell specifically: greyed out whenever the most
    /// recent close isn't from today in Switzerland -- market not open yet,
    /// a weekend, a holiday -- so a same-looking number is never mistaken
    /// for a live intraday move. Different instruments in the same table
    /// can disagree (e.g. DAX open while the S&P 500 hasn't started yet),
    /// so this is judged per row from that row's own `asOf` date, not a
    /// single "is the table stale" flag.
    static func dayChangeTone(percent: Double?, asOf: Date?) -> ValueTone {
        guard percent != nil else { return .neutral }
        guard let asOf, zurichCalendar.isDateInToday(asOf) else { return .muted }
        return tone(for: percent)
    }

    /// "Stand: 10.09.2026, 14:32" -- shown so it's obvious the data is a
    /// snapshot, not live.
    static func asOf(_ date: Date?) -> String {
        guard let date else { return "Noch keine Daten" }
        return "Stand: \(date.formatted(.dateTime.locale(swissLocale).day(.twoDigits).month(.twoDigits).year().hour().minute()))"
    }

}

/// The color role of a value in the table. A row picks the colors of its
/// background: the yellow cursor row needs darker colors in dark mode.
enum ValueTone {
    case positive
    case negative
    case neutral
    /// A "Tag" value that is not from today.
    case muted

    var color: Color {
        switch self {
        case .positive: Theme.positive
        case .negative: Theme.negative
        case .neutral: Theme.neutral
        case .muted: Theme.mutedText
        }
    }

    var cursorColor: Color {
        switch self {
        case .positive: Theme.cursorPositive
        case .negative: Theme.cursorNegative
        case .neutral: Theme.cursorText
        case .muted: Theme.cursorMutedText
        }
    }
}
