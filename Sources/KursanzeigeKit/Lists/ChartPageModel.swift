import Observation

/// The chart page: the chart of one row of the table, and the bottom bar
/// that steps through the charts of the shown group. The rows are the
/// instruments in the order of the table when the page opened. The page
/// opens silently on the tapped row, and keeps the chosen range on each
/// step. A chart reads its summary, e.g. „Nestlé, 1 Jahr, …“. Vorlesen
/// reads only the shown chart: the person decides when the next chart shows.
@Observable
@MainActor
public final class ChartPageModel: Identifiable {
    /// The bottom bar and the remote commands use it.
    public let reader: ListReader
    /// The shown chart: the chart of the cursor row.
    public private(set) var chart: InstrumentChartViewModel
    /// The direction of the last step, so the next chart slides in from that side.
    public private(set) var lastStep = PageStep.next

    private let instruments: [Instrument]
    private let makeChart: @MainActor (Instrument, ChartRange) -> InstrumentChartViewModel

    /// The symbol of the first chart. It stays the same while the page is
    /// open, so `fullScreenCover(item:)` does not open the page again.
    public nonisolated let id: String

    /// - Parameter makeChart: makes the chart of an instrument with a range.
    ///   `MainViewModel.makeChartViewModel(for:range:)` gives it.
    public convenience init(
        instruments: [Instrument],
        shownInstrument: Instrument,
        makeChart: @escaping @MainActor (Instrument, ChartRange) -> InstrumentChartViewModel,
        speaker: any Speaking,
        voiceOver: any VoiceOverAnnouncing
    ) {
        let services = ListServices(speaker: speaker, sleeper: TaskSleeper(), cursorStore: UnsavedCursorStore(), voiceOver: voiceOver)
        self.init(instruments: instruments, shownInstrument: shownInstrument, makeChart: makeChart, services: services)
    }

    init(
        instruments: [Instrument],
        shownInstrument: Instrument,
        makeChart: @escaping @MainActor (Instrument, ChartRange) -> InstrumentChartViewModel,
        services: ListServices
    ) {
        let groupName = shownInstrument.group.displayName
        self.id = shownInstrument.symbol
        self.instruments = instruments
        self.makeChart = makeChart
        self.chart = makeChart(shownInstrument, .oneYear)
        // A chart page never changes the saved cursor of the table.
        let chartServices = services.makeCopy(cursorStore: UnsavedCursorStore())
        self.reader = ListReader(rows: [], list: groupName, advancesAutomatically: false, services: chartServices)
        reader.replaceRows(instruments.enumerated().map { index, instrument in
            SpokenRow(id: instrument.symbol, title: instrument.name) { [weak self] in
                await self?.makeSpeech(rowIndex: index) ?? ""
            }
        })
        reader.placeCursor(at: instruments.firstIndex(of: shownInstrument) ?? 0)
        reader.onCursorMove = { [weak self] index in self?.showChart(rowIndex: index) }
    }

    /// A sideways swipe: the same as Vorherige or Nächste.
    public func show(_ step: PageStep) {
        switch step {
        case .previous: reader.showPrevious()
        case .next: reader.showNext()
        }
    }

    /// Shows `range`. During Vorlesen, the chart reads again with its new change.
    public func select(_ range: ChartRange) {
        chart.select(range)
        reader.rereadCursorRow()
    }

    /// Stops the voice. Call it when the page closes.
    public func close() {
        reader.pauseReading()
    }

    private func showChart(rowIndex: Int) {
        let instrument = instruments[rowIndex]
        guard instrument != chart.instrument else { return }
        let shownIndex = instruments.firstIndex(of: chart.instrument) ?? 0
        lastStep = rowIndex > shownIndex ? .next : .previous
        chart = makeChart(instrument, chart.range)
    }

    /// The text of a row waits for the history of its chart. Each chart of
    /// a row shows before it reads, so the shown chart is the right one.
    private func makeSpeech(rowIndex: Int) async -> String {
        let instrument = instruments[rowIndex]
        let rowChart = chart.instrument == instrument ? chart : makeChart(instrument, chart.range)
        await rowChart.load()
        let summary = rowChart.spokenSummary() ?? "\(instrument.name), kein Verlauf"
        return "\(summary)."
    }
}
