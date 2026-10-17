import Observation

/// The cursor and the voice of the table on the main page. Each group is
/// one list with its own saved cursor. A row reads „Nummer drei.“ and then
/// its name, price and day change.
@Observable
@MainActor
public final class TableListModel {
    /// The bottom bar and the remote commands use it.
    public let reader: ListReader
    private var group: MarketGroup
    private var instruments: [Instrument]

    /// The instrument of the cursor row. Nil when the group has no rows.
    public var cursorInstrument: Instrument? {
        instruments.indices.contains(reader.cursorIndex) ? instruments[reader.cursorIndex] : nil
    }

    /// The table starts silently on the saved cursor row of `group`.
    public convenience init(group: MarketGroup, rows: [InstrumentRow], speaker: any Speaking, voiceOver: any VoiceOverAnnouncing) {
        let services = ListServices(speaker: speaker, sleeper: TaskSleeper(), cursorStore: UserDefaultsCursorStore(), voiceOver: voiceOver)
        self.init(group: group, rows: rows, services: services)
    }

    init(group: MarketGroup, rows: [InstrumentRow], services: ListServices) {
        self.group = group
        self.instruments = rows.map(\.instrument)
        self.reader = ListReader(rows: Self.makeSpokenRows(rows), list: group.displayName, services: services)
    }

    /// Gives the table its shown rows. A new group during Vorlesen says the
    /// group name and its cursor row. The same group with a new sort or new
    /// prices keeps the cursor on its instrument, silently.
    public func show(group newGroup: MarketGroup, rows: [InstrumentRow]) {
        instruments = rows.map(\.instrument)
        let spokenRows = Self.makeSpokenRows(rows)
        if newGroup == group {
            reader.replaceRows(spokenRows)
        } else {
            group = newGroup
            reader.showList(newGroup.displayName, rows: spokenRows, introduction: "\(newGroup.displayName).")
        }
    }

    /// A tap on a row opens its chart: the cursor goes there without speech.
    /// The closed chart page also puts the cursor on its last chart.
    public func placeCursor(on instrument: Instrument) {
        guard let index = instruments.firstIndex(of: instrument) else { return }
        reader.placeCursor(at: index)
    }

    /// Öffnen. Stops the voice and gives the instrument of the cursor row,
    /// whose chart then opens. Nil when the group has no rows.
    public func openCursorRow() -> Instrument? {
        reader.pauseReading()
        return cursorInstrument
    }

    private static func makeSpokenRows(_ rows: [InstrumentRow]) -> [SpokenRow] {
        rows.enumerated().map { index, row in
            let text = TableSpeech.text(row, number: index + 1)
            return SpokenRow(id: row.id, title: row.instrument.name, speech: { text })
        }
    }
}
