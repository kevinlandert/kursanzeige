import Foundation
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
    /// True while „Probe hören“ of the settings plays.
    private(set) var isPlayingSample = false
    /// Counts the samples, so a late end of a stopped sample does not
    /// reset the state of the next one.
    @ObservationIgnored private var sampleCount = 0

    @ObservationIgnored private let speaker: SynthesizerSpeaker
    @ObservationIgnored private let voiceOver: VoiceOverAnnouncer
    @ObservationIgnored private let router: RemoteCommandRouter
    @ObservationIgnored private let remoteCommandHandler: RemoteCommandHandler
    @ObservationIgnored private let nowPlayingPublisher: NowPlayingPublisher
    /// Set after the other values, because it calls back into this model.
    @ObservationIgnored private var audioSessionObserver: AudioSessionObserver?

    init() {
        let viewModel = MainViewModel()
        let speaker = SynthesizerSpeaker { Self.storedSpeechRate }
        let voiceOver = VoiceOverAnnouncer()
        let table = TableListModel(
            group: viewModel.selectedGroup, rows: viewModel.displayedRows,
            settings: Self.makeSpeechSettings(viewModel: viewModel, columns: Self.storedSpokenColumns),
            speaker: speaker, voiceOver: voiceOver
        )
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

    /// Gives the table the rows that the view model shows now, with the
    /// columns that the voice reads.
    func showRows(spokenColumns: SpokenColumns) {
        let settings = Self.makeSpeechSettings(viewModel: viewModel, columns: spokenColumns)
        table.show(group: viewModel.selectedGroup, rows: viewModel.displayedRows, settings: settings)
    }

    /// „Probe hören“: reads the cursor row of the table with the chosen
    /// columns and tempo. A second press stops it.
    func toggleSample() {
        guard !isPlayingSample else { return stopSample() }
        isPlayingSample = true
        sampleCount += 1
        let sampleIndex = sampleCount
        let text = table.sampleText
        Task {
            _ = await speaker.speak(text)
            guard sampleIndex == sampleCount else { return }
            isPlayingSample = false
        }
    }

    /// Stops „Probe hören“, e.g. when the tempo changes: the new tempo
    /// applies only to the next text.
    func stopSample() {
        guard isPlayingSample else { return }
        isPlayingSample = false
        speaker.stop()
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
        speaker.stop()
        router.showTable()
    }

    /// The tempo that the settings store. A new install reads at „Normal“.
    private static var storedSpeechRate: SpeechRate {
        UserDefaults.standard.string(forKey: SpeechRate.storageKey).flatMap(SpeechRate.init) ?? .standard
    }

    /// The columns that the settings store. Without a stored value, Kurs and Tag.
    private static var storedSpokenColumns: SpokenColumns {
        guard UserDefaults.standard.object(forKey: SpokenColumns.storageKey) != nil else { return .standard }
        return SpokenColumns(rawValue: UserDefaults.standard.integer(forKey: SpokenColumns.storageKey))
    }

    private static func makeSpeechSettings(viewModel: MainViewModel, columns: SpokenColumns) -> TableSpeechSettings {
        TableSpeechSettings(columns: columns, rangeMode: viewModel.rangeMode, oneYearMode: viewModel.oneYearMode)
    }

    /// Ends Vorlesen on each page and the sample, and stops the voice.
    func stopAllSpeech() {
        table.reader.pauseReading()
        chartPage?.close()
        stopSample()
    }
}
