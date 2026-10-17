import Observation
import os

/// The cursor and the voice of one list, with the rules of the bottom bar.
/// The table and the chart page use the same rules.
///
/// - A cursor move on the screen is silent: the person sees the yellow
///   row. A move from the AirPods or the lock screen reads the new row,
///   because the screen can be off. At an end of the list the voice says
///   „Anfang der Liste.“ or „Ende der Liste.“, and the cursor stays. A list
///   without rows says „Keine Kurse.“, also for Vorlesen.
/// - Vorlesen reads from the cursor. After each row it waits 1 s and goes
///   to the next row, if the list advances automatically. At the end it
///   says „Ende der Liste.“ and stops. The chart page does not advance:
///   Vorlesen reads the shown chart, and only a step shows the next chart.
///   A voice that stops from outside, for example after an audio
///   interruption, also ends Vorlesen.
/// - A cursor move during Vorlesen goes on with Vorlesen from the new row.
///   Nächste on the last row and Vorherige on the first row end Vorlesen.
/// - While VoiceOver runs, VoiceOver announces the row after each move and
///   the messages, because its focus stays on the button. Vorlesen still
///   speaks with the voice of the app.
@Observable
@MainActor
public final class ListReader {
    /// The time between two rows of Vorlesen, in seconds.
    static let pauseBetweenRows = 1.0
    private static let logger = Logger(subsystem: "com.kevinlandert.Kursanzeige", category: "Lists")

    /// The index of the cursor row. 0 also when the list has no rows.
    public private(set) var cursorIndex: Int
    /// True while Vorlesen runs: from the start until Pause or the end of the list.
    public private(set) var isReading = false
    /// The name of the list, e.g. „Schweiz“. The cursor store keeps the
    /// cursor under it, and the lock screen shows it.
    public private(set) var list: String
    /// Gets the new index after each cursor move. The chart page then shows
    /// the chart of that row.
    @ObservationIgnored var onCursorMove: ((Int) -> Void)?

    /// The id of the cursor row. Nil when the list has no rows.
    public var cursorRowId: String? {
        rows.indices.contains(cursorIndex) ? rows[cursorIndex].id : nil
    }

    /// „Nummer 3 von 8 ausgewählt“, or „Liest vor · Nummer 3 von 8“.
    public var statusText: String {
        ListTexts.status(cursorIndex: cursorIndex, rowCount: rows.count, isReading: isReading)
    }

    public var statusStyle: StatusStyle {
        isReading ? .reading : .idle
    }

    /// The values of the lock screen for the cursor row.
    public var nowPlayingItem: NowPlayingItem {
        let title = rows.indices.contains(cursorIndex) ? rows[cursorIndex].title : ListTexts.emptyListStatus
        return NowPlayingItem(title: title, listName: list, isReading: isReading)
    }

    private var rows: [SpokenRow]
    private let advancesAutomatically: Bool
    private let cursorStore: any ListCursorStoring
    private let voiceOver: any VoiceOverAnnouncing
    private let speech: SpeechRunner

    /// Puts the cursor on the saved row of the list. Without a saved row,
    /// or when that row is gone, the cursor is on the first row.
    /// - Parameter advancesAutomatically: false when Vorlesen reads only the cursor row.
    init(rows: [SpokenRow], list: String, advancesAutomatically: Bool = true, services: ListServices) {
        self.cursorIndex = Self.findCursorIndex(in: rows, rowId: services.cursorStore.loadCursorRowId(list: list))
        self.rows = rows
        self.list = list
        self.advancesAutomatically = advancesAutomatically
        self.cursorStore = services.cursorStore
        self.voiceOver = services.voiceOver
        self.speech = SpeechRunner(speaker: services.speaker, sleeper: services.sleeper)
    }

    /// Vorherige. On the first row it says the start of the list.
    /// - Parameter readsRow: true for a command from the AirPods or the lock screen.
    public func showPrevious(readsRow: Bool = false) {
        if rows.isEmpty {
            speakOrAnnounce(ListTexts.emptyList)
        } else if cursorIndex > 0 {
            moveCursor(to: cursorIndex - 1, readsRow: readsRow)
        } else {
            speakAnnouncement(ListTexts.listStart)
        }
    }

    /// Nächste. On the last row it says the end of the list. During
    /// Vorlesen it also ends Vorlesen, as at the end of the list.
    /// - Parameter readsRow: true for a command from the AirPods or the lock screen.
    public func showNext(readsRow: Bool = false) {
        if rows.isEmpty {
            speakOrAnnounce(ListTexts.emptyList)
        } else if cursorIndex + 1 < rows.count {
            moveCursor(to: cursorIndex + 1, readsRow: readsRow)
        } else {
            speakAnnouncement(ListTexts.listEnd)
        }
    }

    /// Vorlesen. Has no effect while Vorlesen runs. A list without rows
    /// says „Keine Kurse.“, as Vorherige and Nächste do.
    public func startReading() {
        guard !isReading else { return }
        guard !rows.isEmpty else { return speakOrAnnounce(ListTexts.emptyList) }
        isReading = true
        speech.replaceSpeech { await self.readRows() }
    }

    /// Pause. Stops the voice at once, also during the pause between rows.
    /// Call it also when the list closes.
    public func pauseReading() {
        isReading = false
        speech.stopSpeech()
    }

    /// The button Vorlesen/Pause.
    public func toggleReading() {
        if isReading {
            pauseReading()
        } else {
            startReading()
        }
    }

    /// The text of the cursor row changed, e.g. after a new range on the
    /// chart page. During Vorlesen, Vorlesen reads the row again. While
    /// VoiceOver runs, VoiceOver gets the new text. Else it stops a text
    /// that plays, because that text can tell the old values.
    public func rereadCursorRow() {
        guard !rows.isEmpty else { return }
        moveCursor(to: cursorIndex, readsRow: false)
    }

    /// Moves the cursor without speech and saves it. The voice goes on.
    /// An index outside the rows changes nothing.
    public func placeCursor(at index: Int) {
        guard rows.indices.contains(index) else { return }
        cursorIndex = index
        cursorStore.saveCursorRowId(rows[index].id, list: list)
        onCursorMove?(index)
    }

    /// Gives the list new rows, for example a new sort or new prices. The
    /// cursor stays on the row with the same id, and Vorlesen goes on with
    /// the new text of the next row. When the cursor row is gone, the
    /// cursor goes to the first row and saves it, and Vorlesen ends
    /// without speech.
    func replaceRows(_ newRows: [SpokenRow]) {
        let newCursorIndex = newRows.firstIndex { $0.id == cursorRowId }
        rows = newRows
        guard let newCursorIndex else {
            stopOwnReading()
            cursorIndex = 0
            if let firstRow = newRows.first {
                cursorStore.saveCursorRowId(firstRow.id, list: list)
            }
            return
        }
        cursorIndex = newCursorIndex
    }

    /// Shows another list, e.g. another group. Vorlesen ends. The cursor
    /// goes to the saved row of the new list. When Vorlesen ran, or while
    /// VoiceOver runs, the voice says the introduction and the cursor row,
    /// so the person hears where they are. Else the change is silent.
    func showList(_ newList: String, rows newRows: [SpokenRow], introduction: String) {
        let wasReading = isReading
        isReading = false
        list = newList
        rows = newRows
        cursorIndex = Self.findCursorIndex(in: newRows, rowId: cursorStore.loadCursorRowId(list: newList))
        guard wasReading || voiceOver.isRunning else { return speech.stopSpeech() }
        let cursorRow = newRows.indices.contains(cursorIndex) ? newRows[cursorIndex] : nil
        speakOrAnnounce(priority: .high) {
            let rowText = await cursorRow?.speech() ?? ListTexts.emptyList
            return "\(introduction) \(rowText)"
        }
    }

    /// Waits until the voice is silent. For tests.
    func waitForSpeech() async {
        await speech.waitForSpeech()
    }

    /// Moves the cursor. During Vorlesen, Vorlesen goes on from the new
    /// row. While VoiceOver runs, VoiceOver gets the row. Else the voice
    /// reads the row only with `readsRow`. A silent move stops the old
    /// text, because it tells about another row.
    private func moveCursor(to index: Int, readsRow: Bool) {
        guard rows.indices.contains(index) else {
            Self.logger.error("Row \(index) is not in the list \(self.list, privacy: .public) with \(self.rows.count) rows.")
            return
        }
        placeCursor(at: index)
        if isReading {
            speech.replaceSpeech { await self.readRows() }
        } else if readsRow || voiceOver.isRunning {
            let row = rows[index]
            speakOrAnnounce { await row.speech() }
        } else {
            speech.stopSpeech()
        }
    }

    /// Speaks a message of the list in place of the text that plays, and
    /// ends Vorlesen.
    private func speakAnnouncement(_ text: String) {
        isReading = false
        speakOrAnnounce(text)
    }

    /// Ends Vorlesen of this list. The table and the chart page share one
    /// voice, so an idle list must not stop it.
    private func stopOwnReading() {
        guard isReading else { return }
        pauseReading()
    }

    /// The index of the row with the id. 0 when no row has it.
    private static func findCursorIndex(in rows: [SpokenRow], rowId: String?) -> Int {
        rows.firstIndex { $0.id == rowId } ?? 0
    }

    private func speakOrAnnounce(_ text: String) {
        speakOrAnnounce { text }
    }

    /// While VoiceOver runs, stops the old text and gives the new text to
    /// VoiceOver. The text can wait, so it comes in the task of the speech.
    private func speakOrAnnounce(
        priority: AnnouncementPriority = .normal,
        text makeText: @escaping @MainActor () async -> String
    ) {
        speech.replaceSpeech {
            let text = await makeText()
            guard !Task.isCancelled else { return }
            if self.voiceOver.isRunning {
                self.voiceOver.announce(text, priority: priority)
            } else {
                await self.speech.speak(text)
            }
        }
    }

    /// The loop of Vorlesen. It reads the cursor row, waits, and moves the
    /// cursor. It stops at once when Pause or a new speech cancels its task.
    private func readRows() async {
        while rows.indices.contains(cursorIndex) {
            let text = await rows[cursorIndex].speech()
            guard await speech.speak(text) else { return endReadingUnlessCancelled() }
            guard advancesAutomatically else {
                isReading = false
                return
            }
            guard await speech.pause(for: Self.pauseBetweenRows) else { return }
            guard cursorIndex + 1 < rows.count else { break }
            placeCursor(at: cursorIndex + 1)
        }
        isReading = false
        await speech.speak(ListTexts.listEnd)
    }

    /// A text that did not finish ends Vorlesen, because the voice stopped
    /// from outside. A cancelled task changes nothing: Pause or the new
    /// speech that cancelled it sets the state.
    private func endReadingUnlessCancelled() {
        guard !Task.isCancelled else { return }
        isReading = false
    }
}
