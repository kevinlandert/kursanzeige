import Foundation
import Testing
@testable import KursanzeigeKit

private let nestle = Instrument(symbol: "NESN.SW", name: "Nestlé", group: .switzerland)
private let novartis = Instrument(symbol: "NOVN.SW", name: "Novartis", group: .switzerland)
private let roche = Instrument(symbol: "ROG.SW", name: "Roche", group: .switzerland)
private let apple = Instrument(symbol: "AAPL", name: "Apple", group: .usa)

private func createRow(_ instrument: Instrument, price: Double? = nil) -> InstrumentRow {
    InstrumentRow(
        instrument: instrument, price: price, asOf: nil, dayChangePercent: nil,
        threeMonthChangePercent: nil, oneYearChangePercent: nil
    )
}

@MainActor
private func createModel(_ fakes: ListFakes, rows: [InstrumentRow] = [createRow(nestle), createRow(novartis), createRow(roche)]) -> TableListModel {
    TableListModel(group: .switzerland, rows: rows, services: fakes.services)
}

@Suite("TableListModel")
@MainActor
struct TableListModelTests {
    @Test("a row reads its number as a word before its name and price")
    func rowReadsNumberAsWord() async {
        let fakes = ListFakes()
        let model = createModel(fakes, rows: [createRow(nestle, price: 77.96), createRow(novartis)])

        model.reader.showNext(readsRow: true)
        await model.reader.waitForSpeech()

        #expect(fakes.speaker.spokenTexts == ["Nummer zwei. Novartis, kein Kurs."])
    }

    @Test("a new group during Vorlesen says the group name and its cursor row")
    func newGroupSaysGroupAndCursorRow() async {
        let fakes = ListFakes(holdsSpeech: true)
        let model = createModel(fakes)
        model.reader.startReading()
        await waitUntil { fakes.speaker.isSpeaking }

        model.show(group: .usa, rows: [createRow(apple)])
        await waitUntil { fakes.speaker.spokenTexts.count == 2 }

        #expect(fakes.speaker.spokenTexts.last == "USA. Nummer eins. Apple, kein Kurs.")
        #expect(model.reader.statusText == "Nummer 1 von 1 ausgewählt")
    }

    @Test("each group keeps its own cursor")
    func eachGroupKeepsItsCursor() {
        let fakes = ListFakes()
        let model = createModel(fakes)
        model.reader.placeCursor(at: 2)

        model.show(group: .usa, rows: [createRow(apple)])
        model.show(group: .switzerland, rows: [createRow(nestle), createRow(novartis), createRow(roche)])

        #expect(model.cursorInstrument == roche)
    }

    @Test("a new sort of the same group keeps the cursor on its instrument, silently")
    func newSortKeepsCursorOnInstrument() async {
        let fakes = ListFakes()
        let model = createModel(fakes)
        model.reader.placeCursor(at: 0)

        model.show(group: .switzerland, rows: [createRow(roche), createRow(novartis), createRow(nestle)])
        await model.reader.waitForSpeech()

        #expect(model.reader.cursorIndex == 2)
        #expect(model.cursorInstrument == nestle)
        #expect(fakes.speaker.spokenTexts.isEmpty)
    }

    @Test("after a new sort, a row reads its new number")
    func rowReadsNewNumberAfterSort() async {
        let fakes = ListFakes()
        let model = createModel(fakes)

        model.show(group: .switzerland, rows: [createRow(roche), createRow(novartis), createRow(nestle)])
        model.reader.showPrevious(readsRow: true)
        await model.reader.waitForSpeech()

        #expect(fakes.speaker.spokenTexts == ["Nummer zwei. Novartis, kein Kurs."])
    }

    @Test("a tap on a row puts the cursor there without speech")
    func tapPutsCursorWithoutSpeech() async {
        let fakes = ListFakes()
        let model = createModel(fakes)

        model.placeCursor(on: roche)
        await model.reader.waitForSpeech()

        #expect(model.reader.cursorIndex == 2)
        #expect(fakes.speaker.spokenTexts.isEmpty)
    }

    @Test("Öffnen stops the voice and gives the instrument of the cursor row")
    func openStopsVoiceAndGivesCursorInstrument() async {
        let fakes = ListFakes(holdsSpeech: true)
        let model = createModel(fakes)
        model.reader.startReading()
        await waitUntil { fakes.speaker.isSpeaking }

        let opened = model.openCursorRow()

        #expect(opened == nestle)
        #expect(model.reader.isReading == false)
        #expect(fakes.speaker.isSpeaking == false)
    }

    @Test("Öffnen on an empty group gives no instrument")
    func openOnEmptyGroupGivesNothing() {
        let model = createModel(ListFakes(), rows: [])

        #expect(model.openCursorRow() == nil)
    }

    @Test("the lock screen shows the instrument name and the group")
    func nowPlayingShowsInstrumentAndGroup() {
        let model = createModel(ListFakes())

        #expect(model.reader.nowPlayingItem == NowPlayingItem(title: "Nestlé", listName: "Schweiz", isReading: false))
    }
}
