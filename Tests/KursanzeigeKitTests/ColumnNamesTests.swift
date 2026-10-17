import Testing
@testable import KursanzeigeKit

/// The table header, the range buttons and the voice name the two range
/// columns. Each name has one source, so the three always agree.
@Suite("Column names")
struct ColumnNamesTests {
    @Test("the short range column is „1-Mt.“ or „3-Mt.“ in the header and a full word elsewhere")
    func shortRangeNames() {
        #expect(RangeMode.oneMonth.headerTitle == "1-Mt.")
        #expect(RangeMode.threeMonth.headerTitle == "3-Mt.")
        #expect(RangeMode.oneMonth.choiceTitle == "1 Monat")
        #expect(RangeMode.threeMonth.choiceTitle == "3 Monate")
        #expect(RangeMode.oneMonth.spokenName == "1 Monat")
        #expect(RangeMode.threeMonth.spokenName == "3 Monate")
    }

    /// The voice would spell the letters of the English „YTD“.
    @Test("the long range column says „seit Jahresbeginn“ in place of „YTD“")
    func longRangeNames() {
        #expect(OneYearMode.trailing.headerTitle == "1-Jahr")
        #expect(OneYearMode.yearToDate.headerTitle == "YTD")
        #expect(OneYearMode.trailing.choiceTitle == "1 Jahr")
        #expect(OneYearMode.yearToDate.choiceTitle == "YTD")
        #expect(OneYearMode.trailing.spokenName == "1 Jahr")
        #expect(OneYearMode.yearToDate.spokenName == "seit Jahresbeginn")
    }
}
