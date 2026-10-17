import Observation

/// The cursor and the voice of the table on the main page. Each group is
/// one list with its own saved cursor. A row reads its name and the
/// columns of the settings (see `TableSpeech`).
@Observable
@MainActor
public final class TableListModel {
    /// The bottom bar and the remote commands use it.
    public let reader: ListReader
    private var group: MarketGroup
    private var rows: [InstrumentRow]
    private var settings: TableSpeechSettings

    /// The instrument of the cursor row. Nil when the group has no rows.
    public var cursorInstrument: Instrument? {
        cursorRow?.instrument
    }

    /// „Probe hören“ in the settings reads the cursor row with the chosen
    /// columns, so the person hears real values.
    public var sampleText: String {
        cursorRow.map { TableSpeech.text($0, settings: settings) } ?? ListTexts.emptyList
    }

    private var cursorRow: InstrumentRow? {
        rows.indices.contains(reader.cursorIndex) ? rows[reader.cursorIndex] : nil
    }

    /// The table starts silently on the saved cursor row of `group`.
    public convenience init(
        group: MarketGroup, rows: [InstrumentRow], settings: TableSpeechSettings,
        speaker: any Speaking, voiceOver: any VoiceOverAnnouncing
    ) {
        let services = ListServices(speaker: speaker, sleeper: TaskSleeper(), cursorStore: UserDefaultsCursorStore(), voiceOver: voiceOver)
        self.init(group: group, rows: rows, settings: settings, services: services)
    }

    init(group: MarketGroup, rows: [InstrumentRow], settings: TableSpeechSettings = .standard, services: ListServices) {
        self.group = group
        self.rows = rows
        self.settings = settings
        self.reader = ListReader(rows: Self.makeSpokenRows(rows, settings: settings), list: group.displayName, services: services)
    }

    /// Gives the table its shown rows. A new group during Vorlesen says the
    /// group name and its cursor row. In the same group, the cursor stays
    /// on its instrument, silently.
    public func show(group newGroup: MarketGroup, rows newRows: [InstrumentRow], settings newSettings: TableSpeechSettings) {
        rows = newRows
        settings = newSettings
        let spokenRows = Self.makeSpokenRows(newRows, settings: newSettings)
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
        guard let index = rows.firstIndex(where: { $0.instrument == instrument }) else { return }
        reader.placeCursor(at: index)
    }

    /// Öffnen. Stops the voice and gives the instrument of the cursor row,
    /// whose chart then opens. Nil when the group has no rows.
    public func openCursorRow() -> Instrument? {
        reader.pauseReading()
        return cursorInstrument
    }

    private static func makeSpokenRows(_ rows: [InstrumentRow], settings: TableSpeechSettings) -> [SpokenRow] {
        rows.map { row in
            let text = TableSpeech.text(row, settings: settings)
            return SpokenRow(id: row.id, title: row.instrument.name, speech: { text })
        }
    }
}
