import KursanzeigeKit
import Observation

/// The models of the app and the connections to iOS that must exist once:
/// the voice, the AirPods and lock screen commands, and the audio
/// interruptions. `KursanzeigeApp` makes it once for the full app life.
/// It also tells the router which page shows, so a remote command goes to
/// the page that the person sees.
@Observable
@MainActor
final class AppModel {
    let viewModel: MainViewModel
    /// The cursor and the voice of the table.
    let table: TableListModel
    /// The open chart page. Nil while the table shows.
    private(set) var chartPage: ChartPageModel?

    @ObservationIgnored private let speaker: SynthesizerSpeaker
    @ObservationIgnored private let voiceOver: VoiceOverAnnouncer
    @ObservationIgnored private let router: RemoteCommandRouter
    @ObservationIgnored private let remoteCommandHandler: RemoteCommandHandler
    @ObservationIgnored private let nowPlayingPublisher: NowPlayingPublisher
    /// Set after the other values, because it calls back into this model.
    @ObservationIgnored private var audioSessionObserver: AudioSessionObserver?

    init() {
        let viewModel = MainViewModel()
        let speaker = SynthesizerSpeaker()
        let voiceOver = VoiceOverAnnouncer()
        let table = TableListModel(group: viewModel.selectedGroup, rows: viewModel.displayedRows, speaker: speaker, voiceOver: voiceOver)
        let router = RemoteCommandRouter(tableReader: table.reader)
        self.viewModel = viewModel
        self.speaker = speaker
        self.voiceOver = voiceOver
        self.table = table
        self.router = router
        self.remoteCommandHandler = RemoteCommandHandler(router: router)
        self.nowPlayingPublisher = NowPlayingPublisher(router: router)
        audioSessionObserver = AudioSessionObserver { [weak self] in self?.stopAllSpeech() }
    }

    /// Gives the table the rows that the view model shows now.
    func showRows() {
        table.show(group: viewModel.selectedGroup, rows: viewModel.displayedRows)
    }

    /// A tap on a row, or Öffnen: the chart page opens on that row. The
    /// page steps through the rows in the order of the table.
    func openChart(for instrument: Instrument) {
        table.reader.pauseReading()
        table.placeCursor(on: instrument)
        let page = ChartPageModel(
            instruments: viewModel.displayedRows.map(\.instrument),
            shownInstrument: instrument,
            makeChart: { [viewModel] instrument, range in viewModel.makeChartViewModel(for: instrument, range: range) },
            speaker: speaker,
            voiceOver: voiceOver
        )
        chartPage = page
        router.showChart(page.reader)
    }

    /// The table shows again, with the cursor on the last shown chart.
    func closeChart() {
        guard let chartPage else { return }
        chartPage.close()
        table.placeCursor(on: chartPage.chart.instrument)
        self.chartPage = nil
        router.showTable()
    }

    /// The settings have no list. The remote commands then do nothing.
    func openSettings() {
        stopAllSpeech()
        router.showSettings()
    }

    func closeSettings() {
        router.showTable()
    }

    /// Ends Vorlesen on each page and stops the voice.
    func stopAllSpeech() {
        table.reader.pauseReading()
        chartPage?.close()
    }
}
