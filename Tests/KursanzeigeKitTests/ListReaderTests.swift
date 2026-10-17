import Foundation
import Testing
@testable import KursanzeigeKit

/// A reader of the list „Schweiz“ and its fakes.
@MainActor
private struct ReaderFixture {
    let reader: ListReader
    let fakes: ListFakes
    let list = "Schweiz"

    var speaker: FakeSpeaker { fakes.speaker }
    var sleeper: FakeSleeper { fakes.sleeper }
    var voiceOver: FakeVoiceOver { fakes.voiceOver }
    var savedRowId: String? { fakes.cursorStore.loadCursorRowId(list: list) }
}

/// The row ids are „row1“, „row2“ and so on, in the order of the texts.
@MainActor
private func createReaderFixture(
    rowTexts: [String] = ["Eins.", "Zwei.", "Drei."],
    savedRowId: String? = nil,
    advancesAutomatically: Bool = true,
    holdsSpeech: Bool = false,
    holdsPause: Bool = false
) -> ReaderFixture {
    let fakes = ListFakes(holdsSpeech: holdsSpeech, holdsPause: holdsPause)
    if let savedRowId {
        fakes.cursorStore.saveCursorRowId(savedRowId, list: "Schweiz")
    }
    let reader = ListReader(
        rows: createSpokenRows(rowTexts), list: "Schweiz", advancesAutomatically: advancesAutomatically, services: fakes.services
    )
    return ReaderFixture(reader: reader, fakes: fakes)
}

/// Rows with the ids „row1“, „row2“ and so on. The title is the text
/// without the full stop.
private func createSpokenRows(_ rowTexts: [String], idPrefix: String = "row") -> [SpokenRow] {
    rowTexts.enumerated().map { index, text in
        SpokenRow(id: "\(idPrefix)\(index + 1)", title: String(text.dropLast()), speech: { text })
    }
}

@Suite("ListReader")
@MainActor
struct ListReaderTests {
    // MARK: Cursor

    @Test("a list without a saved cursor starts on the first row and is silent")
    func startsOnFirstRow() {
        let fixture = createReaderFixture()

        #expect(fixture.reader.cursorIndex == 0)
        #expect(fixture.reader.isReading == false)
        #expect(fixture.speaker.spokenTexts.isEmpty)
    }

    @Test("the cursor starts on the saved row of the list")
    func startsOnSavedRow() {
        let fixture = createReaderFixture(savedRowId: "row3")

        #expect(fixture.reader.cursorIndex == 2)
    }

    @Test("a saved row that is gone puts the cursor on the first row")
    func goneSavedRowStartsOnFirstRow() {
        let fixture = createReaderFixture(savedRowId: "row9")

        #expect(fixture.reader.cursorIndex == 0)
    }

    @Test("Nächste moves the cursor down silently and saves it")
    func nextMovesDownSilently() async {
        let fixture = createReaderFixture()

        fixture.reader.showNext()
        await fixture.reader.waitForSpeech()

        #expect(fixture.reader.cursorIndex == 1)
        #expect(fixture.speaker.spokenTexts.isEmpty)
        #expect(fixture.savedRowId == "row2")
    }

    @Test("Vorherige moves the cursor up silently")
    func previousMovesUpSilently() async {
        let fixture = createReaderFixture(savedRowId: "row3")

        fixture.reader.showPrevious()
        await fixture.reader.waitForSpeech()

        #expect(fixture.reader.cursorIndex == 1)
        #expect(fixture.speaker.spokenTexts.isEmpty)
    }

    @Test("a move that reads the row, as from the AirPods, reads the new row")
    func moveThatReadsRowReadsNewRow() async {
        let fixture = createReaderFixture(savedRowId: "row2")

        fixture.reader.showNext(readsRow: true)
        await fixture.reader.waitForSpeech()
        fixture.reader.showPrevious(readsRow: true)
        await fixture.reader.waitForSpeech()

        #expect(fixture.speaker.spokenTexts == ["Drei.", "Zwei."])
    }

    @Test("a silent move stops the text of the row before")
    func silentMoveStopsOldText() async {
        let fixture = createReaderFixture(holdsSpeech: true)
        fixture.reader.showNext(readsRow: true)
        await waitUntil { fixture.speaker.isSpeaking }

        fixture.reader.showNext()
        await fixture.reader.waitForSpeech()

        #expect(fixture.speaker.isSpeaking == false)
        #expect(fixture.speaker.spokenTexts == ["Zwei."])
    }

    @Test("Nächste on the last row says „Ende der Liste.“ and keeps the cursor")
    func nextOnLastRowSaysEnd() async {
        let fixture = createReaderFixture(savedRowId: "row3")

        fixture.reader.showNext()
        await fixture.reader.waitForSpeech()

        #expect(fixture.reader.cursorIndex == 2)
        #expect(fixture.speaker.spokenTexts == ["Ende der Liste."])
    }

    @Test("Vorherige on the first row says „Anfang der Liste.“ and keeps the cursor")
    func previousOnFirstRowSaysStart() async {
        let fixture = createReaderFixture()

        fixture.reader.showPrevious()
        await fixture.reader.waitForSpeech()

        #expect(fixture.reader.cursorIndex == 0)
        #expect(fixture.speaker.spokenTexts == ["Anfang der Liste."])
    }

    @Test("Nächste on an empty list says „Keine Kurse.“")
    func nextOnEmptyListSaysNoPrices() async {
        let fixture = createReaderFixture(rowTexts: [])

        fixture.reader.showNext()
        await fixture.reader.waitForSpeech()

        #expect(fixture.speaker.spokenTexts == ["Keine Kurse."])
    }

    @Test("placeCursor moves the cursor and saves it without speech")
    func placeCursorIsSilent() async {
        let fixture = createReaderFixture()

        fixture.reader.placeCursor(at: 1)
        await fixture.reader.waitForSpeech()

        #expect(fixture.reader.cursorIndex == 1)
        #expect(fixture.savedRowId == "row2")
        #expect(fixture.speaker.spokenTexts.isEmpty)
    }

    @Test("placeCursor outside the rows changes nothing")
    func placeCursorOutsideRowsChangesNothing() {
        let fixture = createReaderFixture()

        fixture.reader.placeCursor(at: 7)

        #expect(fixture.reader.cursorIndex == 0)
        #expect(fixture.savedRowId == nil)
    }

    @Test("each cursor move tells the new index to the observer")
    func cursorMoveTellsObserver() async {
        let fixture = createReaderFixture()
        var movedIndices: [Int] = []
        fixture.reader.onCursorMove = { movedIndices.append($0) }

        fixture.reader.showNext()
        fixture.reader.showNext()
        fixture.reader.showPrevious()

        #expect(movedIndices == [1, 2, 1])
    }

    // MARK: Vorlesen

    @Test("Vorlesen reads from the cursor to the end with a pause of 1 s after each row")
    func readingGoesToEndWithPauses() async {
        let fixture = createReaderFixture(savedRowId: "row2")

        fixture.reader.startReading()
        await fixture.reader.waitForSpeech()

        #expect(fixture.speaker.spokenTexts == ["Zwei.", "Drei.", "Ende der Liste."])
        #expect(fixture.sleeper.pauses == [1, 1])
        #expect(fixture.reader.cursorIndex == 2)
        #expect(fixture.reader.isReading == false)
    }

    @Test("Vorlesen saves the cursor of each row that it reads")
    func readingSavesEachCursor() async {
        let fixture = createReaderFixture()

        fixture.reader.startReading()
        await fixture.reader.waitForSpeech()

        #expect(fixture.savedRowId == "row3")
    }

    @Test("Vorlesen without automatic advance reads only the cursor row")
    func readingWithoutAdvanceReadsOneRow() async {
        let fixture = createReaderFixture(advancesAutomatically: false)

        fixture.reader.startReading()
        await fixture.reader.waitForSpeech()

        #expect(fixture.speaker.spokenTexts == ["Eins."])
        #expect(fixture.sleeper.pauses.isEmpty)
        #expect(fixture.reader.cursorIndex == 0)
        #expect(fixture.reader.isReading == false)
    }

    @Test("the cursor goes to the next row only after the speech and the pause")
    func cursorWaitsForSpeechAndPause() async {
        let fixture = createReaderFixture(holdsSpeech: true, holdsPause: true)

        fixture.reader.startReading()
        await waitUntil { fixture.speaker.isSpeaking }
        #expect(fixture.reader.isReading)
        #expect(fixture.reader.cursorIndex == 0)

        fixture.speaker.finishSpeech()
        await waitUntil { fixture.sleeper.isPausing }
        #expect(fixture.reader.cursorIndex == 0)

        fixture.sleeper.finishPause()
        await waitUntil { fixture.speaker.isSpeaking }
        #expect(fixture.reader.cursorIndex == 1)
        #expect(fixture.speaker.spokenTexts == ["Eins.", "Zwei."])
    }

    @Test("Vorlesen on an empty list says „Keine Kurse.“ and does not start")
    func readingEmptyListSaysNoPrices() async {
        let fixture = createReaderFixture(rowTexts: [])

        fixture.reader.startReading()
        await fixture.reader.waitForSpeech()

        #expect(fixture.speaker.spokenTexts == ["Keine Kurse."])
        #expect(fixture.reader.isReading == false)
    }

    @Test("Pause stops the voice at once and ends Vorlesen")
    func pauseStopsAtOnce() async {
        let fixture = createReaderFixture(holdsSpeech: true)
        fixture.reader.startReading()
        await waitUntil { fixture.speaker.isSpeaking }

        fixture.reader.pauseReading()
        await fixture.reader.waitForSpeech()

        #expect(fixture.reader.isReading == false)
        #expect(fixture.speaker.spokenTexts == ["Eins."])
        #expect(fixture.reader.cursorIndex == 0)
    }

    @Test("Pause during the pause between rows ends Vorlesen without a next row")
    func pauseDuringPauseBetweenRowsEndsReading() async {
        let fixture = createReaderFixture(holdsPause: true)
        fixture.reader.startReading()
        await waitUntil { fixture.sleeper.isPausing }

        fixture.reader.pauseReading()
        await fixture.reader.waitForSpeech()

        #expect(fixture.speaker.spokenTexts == ["Eins."])
        #expect(fixture.reader.cursorIndex == 0)
        #expect(fixture.reader.isReading == false)
    }

    @Test("the button Vorlesen/Pause starts and then stops Vorlesen")
    func toggleStartsThenStops() async {
        let fixture = createReaderFixture(holdsSpeech: true)

        fixture.reader.toggleReading()
        await waitUntil { fixture.speaker.isSpeaking }
        #expect(fixture.reader.isReading)

        fixture.reader.toggleReading()
        #expect(fixture.reader.isReading == false)
    }

    @Test("a voice that stops from outside ends Vorlesen")
    func voiceStoppedFromOutsideEndsReading() async {
        let fixture = createReaderFixture(holdsSpeech: true)
        fixture.reader.startReading()
        await waitUntil { fixture.speaker.isSpeaking }

        fixture.speaker.stop()
        await fixture.reader.waitForSpeech()

        #expect(fixture.reader.isReading == false)
        #expect(fixture.speaker.spokenTexts == ["Eins."])
    }

    // MARK: A press during speech

    @Test("Nächste during speech stops the old text before the new text starts")
    func nextDuringSpeechStopsOldText() async {
        let fixture = createReaderFixture(holdsSpeech: true)
        fixture.reader.showNext(readsRow: true)
        await waitUntil { fixture.speaker.isSpeaking }

        fixture.reader.showNext(readsRow: true)
        await waitUntil { fixture.speaker.spokenTexts.count == 2 }
        fixture.speaker.finishSpeech()
        await fixture.reader.waitForSpeech()

        #expect(fixture.speaker.spokenTexts == ["Zwei.", "Drei."])
        #expect(fixture.speaker.largestOverlap == 1)
    }

    @Test("Nächste during Vorlesen goes on with Vorlesen from the new row")
    func nextDuringReadingGoesOnFromNewRow() async {
        let fixture = createReaderFixture(holdsSpeech: true)
        fixture.reader.startReading()
        await waitUntil { fixture.speaker.isSpeaking }

        fixture.reader.showNext()
        await waitUntil { fixture.speaker.spokenTexts.count == 2 }

        #expect(fixture.reader.isReading)
        #expect(fixture.reader.cursorIndex == 1)
        #expect(fixture.speaker.spokenTexts == ["Eins.", "Zwei."])
        #expect(fixture.speaker.largestOverlap == 1)
    }

    @Test("Nächste on the last row during Vorlesen says the end and ends Vorlesen")
    func nextOnLastRowDuringReadingEndsReading() async {
        let fixture = createReaderFixture(savedRowId: "row3", holdsSpeech: true)
        fixture.reader.startReading()
        await waitUntil { fixture.speaker.isSpeaking }

        fixture.reader.showNext()
        await waitUntil { fixture.speaker.spokenTexts.count == 2 }
        fixture.speaker.finishSpeech()
        await fixture.reader.waitForSpeech()

        #expect(fixture.reader.isReading == false)
        #expect(fixture.speaker.spokenTexts == ["Drei.", "Ende der Liste."])
    }

    @Test("during Vorlesen, rereadCursorRow reads the cursor row again")
    func rereadDuringReadingReadsCursorRowAgain() async {
        let fixture = createReaderFixture(savedRowId: "row3", holdsSpeech: true)
        fixture.reader.startReading()
        await waitUntil { fixture.speaker.isSpeaking }

        fixture.reader.rereadCursorRow()
        await waitUntil { fixture.speaker.spokenTexts.count == 2 }

        #expect(fixture.speaker.spokenTexts == ["Drei.", "Drei."])
        #expect(fixture.reader.cursorIndex == 2)
    }

    @Test("without Vorlesen, rereadCursorRow is silent")
    func rereadWithoutReadingIsSilent() async {
        let fixture = createReaderFixture(savedRowId: "row2")

        fixture.reader.rereadCursorRow()
        await fixture.reader.waitForSpeech()

        #expect(fixture.speaker.spokenTexts.isEmpty)
    }

    // MARK: VoiceOver

    @Test("while VoiceOver runs, Nächste gives the row to VoiceOver and the app voice is silent")
    func voiceOverAnnouncesNext() async {
        let fixture = createReaderFixture()
        fixture.voiceOver.isRunning = true

        fixture.reader.showNext()
        await fixture.reader.waitForSpeech()

        #expect(fixture.speaker.spokenTexts.isEmpty)
        #expect(fixture.voiceOver.announcedTexts == ["Zwei."])
        #expect(fixture.voiceOver.announcedPriorities == [.normal])
    }

    @Test("while VoiceOver runs, the end of the list goes to VoiceOver")
    func voiceOverAnnouncesListEnd() async {
        let fixture = createReaderFixture(savedRowId: "row3")
        fixture.voiceOver.isRunning = true

        fixture.reader.showNext()
        await fixture.reader.waitForSpeech()

        #expect(fixture.voiceOver.announcedTexts == ["Ende der Liste."])
    }

    @Test("while VoiceOver runs, Vorlesen still uses the voice of the app")
    func readingWithVoiceOverUsesAppVoice() async {
        let fixture = createReaderFixture(savedRowId: "row3")
        fixture.voiceOver.isRunning = true

        fixture.reader.startReading()
        await fixture.reader.waitForSpeech()

        #expect(fixture.speaker.spokenTexts == ["Drei.", "Ende der Liste."])
        #expect(fixture.voiceOver.announcedTexts.isEmpty)
    }

    // MARK: Other list, new rows

    @Test("another list during Vorlesen stops Vorlesen and says the introduction and the saved cursor row of that list")
    func otherListSaysIntroductionAndCursorRow() async {
        let fixture = createReaderFixture(holdsSpeech: true)
        fixture.fakes.cursorStore.saveCursorRowId("usa2", list: "USA")
        fixture.reader.startReading()
        await waitUntil { fixture.speaker.isSpeaking }

        fixture.reader.showList("USA", rows: createSpokenRows(["Apple.", "Microsoft."], idPrefix: "usa"), introduction: "USA.")
        await waitUntil { fixture.speaker.spokenTexts.count == 2 }
        fixture.speaker.finishSpeech()
        await fixture.reader.waitForSpeech()

        #expect(fixture.reader.isReading == false)
        #expect(fixture.reader.cursorIndex == 1)
        #expect(fixture.speaker.spokenTexts == ["Eins.", "USA. Microsoft."])
    }

    @Test("another list without rows during Vorlesen says the introduction and „Keine Kurse.“")
    func otherEmptyListSaysNoPrices() async {
        let fixture = createReaderFixture(holdsSpeech: true)
        fixture.reader.startReading()
        await waitUntil { fixture.speaker.isSpeaking }

        fixture.reader.showList("USA", rows: [], introduction: "USA.")
        await waitUntil { fixture.speaker.spokenTexts.count == 2 }

        #expect(fixture.speaker.spokenTexts == ["Eins.", "USA. Keine Kurse."])
    }

    @Test("another list without Vorlesen is silent and stops the old text")
    func otherListWithoutReadingIsSilent() async {
        let fixture = createReaderFixture(holdsSpeech: true)
        fixture.reader.showNext(readsRow: true)
        await waitUntil { fixture.speaker.isSpeaking }

        fixture.reader.showList("USA", rows: createSpokenRows(["Apple."]), introduction: "USA.")
        await fixture.reader.waitForSpeech()

        #expect(fixture.speaker.isSpeaking == false)
        #expect(fixture.speaker.spokenTexts == ["Zwei."])
    }

    @Test("while VoiceOver runs, another list goes to VoiceOver with a high priority")
    func voiceOverAnnouncesOtherListWithHighPriority() async {
        let fixture = createReaderFixture()
        fixture.voiceOver.isRunning = true

        fixture.reader.showList("USA", rows: createSpokenRows(["Apple."]), introduction: "USA.")
        await fixture.reader.waitForSpeech()

        #expect(fixture.voiceOver.announcedTexts == ["USA. Apple."])
        #expect(fixture.voiceOver.announcedPriorities == [.high])
    }

    @Test("new rows keep the cursor on the row with the same id, silently")
    func newRowsKeepCursorOnSameId() async {
        let fixture = createReaderFixture(savedRowId: "row2")

        fixture.reader.replaceRows([
            SpokenRow(id: "row3", title: "Drei", speech: { "Drei." }),
            SpokenRow(id: "row2", title: "Zwei", speech: { "Zwei." }),
        ])
        await fixture.reader.waitForSpeech()

        #expect(fixture.reader.cursorIndex == 1)
        #expect(fixture.speaker.spokenTexts.isEmpty)
    }

    @Test("new rows without the cursor row put the cursor on the first row and end Vorlesen")
    func newRowsWithoutCursorRowEndReading() async {
        let fixture = createReaderFixture(savedRowId: "row2", holdsSpeech: true)
        fixture.reader.startReading()
        await waitUntil { fixture.speaker.isSpeaking }

        fixture.reader.replaceRows(createSpokenRows(["Acht."], idPrefix: "other"))
        await fixture.reader.waitForSpeech()

        #expect(fixture.reader.cursorIndex == 0)
        #expect(fixture.reader.isReading == false)
    }

    @Test("new rows without the cursor row save the first row as the cursor")
    func newRowsWithoutCursorRowSaveFirstRow() {
        let fixture = createReaderFixture(savedRowId: "row2")

        fixture.reader.replaceRows(createSpokenRows(["Acht.", "Neun."], idPrefix: "other"))

        #expect(fixture.savedRowId == "other1")
    }

    // MARK: Status line and lock screen

    @Test("the status line tells the name of the selected row")
    func statusTellsSelectedRow() {
        let fixture = createReaderFixture(savedRowId: "row2")

        #expect(fixture.reader.statusText == "Zwei ausgewählt")
        #expect(fixture.reader.statusStyle == .idle)
    }

    @Test("during Vorlesen the status line tells „Liest vor“ and the row")
    func statusTellsReading() async {
        let fixture = createReaderFixture(holdsSpeech: true)

        fixture.reader.startReading()

        #expect(fixture.reader.statusText == "Liest vor · Eins")
        #expect(fixture.reader.statusStyle == .reading)
    }

    @Test("the status line of an empty list says „Keine Kurse“")
    func statusOfEmptyList() {
        let fixture = createReaderFixture(rowTexts: [])

        #expect(fixture.reader.statusText == "Keine Kurse")
    }

    @Test("the lock screen shows the title of the cursor row and the name of the list")
    func nowPlayingShowsCursorRowAndList() async {
        let fixture = createReaderFixture(savedRowId: "row3")

        #expect(fixture.reader.nowPlayingItem == NowPlayingItem(title: "Drei", listName: "Schweiz", isReading: false))
    }
}
