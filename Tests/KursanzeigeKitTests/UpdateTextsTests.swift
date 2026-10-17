import Foundation
import Testing
@testable import KursanzeigeKit

/// The time of the last refresh, under the title „Kurse“. The text is
/// the same as in Schlagzeilen. 16 October 2026 is a Friday.
@Suite("Update texts")
struct UpdateTextsTests {
    @Test("the update line gives the weekday, the date and the time in Zurich")
    func updateLineGivesWeekdayDateAndTime() {
        #expect(UpdateTexts.updateLine(lastUpdate: createDate("2026-10-16T12:27:00Z")) == "Aktualisiert Freitag 16.10.26 14:27")
    }

    @Test("the update line has two digits for the day and the month")
    func updateLineHasTwoDigits() {
        #expect(UpdateTexts.updateLine(lastUpdate: createDate("2027-03-05T08:04:00Z")) == "Aktualisiert Freitag 05.03.27 09:04")
    }

    @Test("an update after midnight in Zurich has the date of Zurich")
    func updateAfterMidnightHasZurichDate() {
        #expect(UpdateTexts.updateLine(lastUpdate: createDate("2026-10-15T22:05:00Z")) == "Aktualisiert Freitag 16.10.26 00:05")
    }

    @Test("without an update the line says that no update was made")
    func missingUpdateSaysSo() {
        #expect(UpdateTexts.updateLine(lastUpdate: nil) == "Noch nicht aktualisiert")
    }

    /// VoiceOver reads „16.10.26“ as three numbers.
    @Test("VoiceOver reads the update with the month name and the hour")
    func updateLabelHasMonthNameAndHour() {
        #expect(UpdateTexts.updateLabel(lastUpdate: createDate("2026-10-16T12:27:00Z")) == "Aktualisiert Freitag, 16. Oktober, 14 Uhr 27")
    }

    @Test("VoiceOver reads a full hour without the minutes")
    func updateLabelReadsFullHour() {
        #expect(UpdateTexts.updateLabel(lastUpdate: createDate("2026-10-14T07:00:00Z")) == "Aktualisiert Mittwoch, 14. Oktober, 9 Uhr")
    }

    @Test("without an update VoiceOver reads the same text as the screen")
    func missingUpdateLabelSaysSo() {
        #expect(UpdateTexts.updateLabel(lastUpdate: nil) == "Noch nicht aktualisiert")
    }

    private func createDate(_ text: String) -> Date {
        try! Date(text, strategy: .iso8601)
    }
}
