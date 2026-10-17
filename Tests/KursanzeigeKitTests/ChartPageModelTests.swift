import Foundation
import Testing
@testable import KursanzeigeKit

private let utcCalendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
}()

private let fetchTime = utcCalendar.date(from: DateComponents(year: 2026, month: 10, day: 15))!

private let nestle = Instrument(symbol: "NESN.SW", name: "Nestlé", group: .switzerland)
private let novartis = Instrument(symbol: "NOVN.SW", name: "Novartis", group: .switzerland)
private let roche = Instrument(symbol: "ROG.SW", name: "Roche", group: .switzerland)

private func close(_ year: Int, _ month: Int, _ day: Int, _ value: Double) -> ClosePoint {
    ClosePoint(date: utcCalendar.date(from: DateComponents(year: year, month: month, day: day))!, close: value)
}

/// One year goes from 40 to 65, plus 62,5 %. Five years go from 10 to 65.
private let closes = [
    close(2021, 10, 15, 10),
    close(2025, 10, 15, 40),
    close(2026, 4, 1, 50),
    close(2026, 10, 15, 65),
]

private let storedHistory = PriceHistory(closes: closes, unit: nil, fetchedAt: fetchTime)

/// Gives the stored closes, or the closes of the fetch result when it fails.
private struct FixedFetcher: PriceFetching {
    var error: FetchError?

    func fetchCloses(for symbol: String) async throws -> FetchedCloses {
        if let error { throw error }
        return FetchedCloses(closes: closes)
    }
}

/// The charts of Nestlé, Novartis and Roche, opened on `shown`. Only the
/// symbols in `storedSymbols` have a stored history.
@MainActor
private func createModel(
    _ fakes: ListFakes,
    shown: Instrument = novartis,
    storedSymbols: Set<String> = [nestle.symbol, novartis.symbol, roche.symbol],
    fetcher: FixedFetcher = FixedFetcher()
) -> ChartPageModel {
    ChartPageModel(
        instruments: [nestle, novartis, roche],
        shownInstrument: shown,
        makeChart: { instrument, range in
            InstrumentChartViewModel(
                instrument: instrument,
                range: range,
                storedHistory: storedSymbols.contains(instrument.symbol) ? storedHistory : nil,
                fetcher: fetcher,
                calendar: utcCalendar,
                now: { fetchTime }
            )
        },
        services: fakes.services
    )
}

@Suite("ChartPageModel")
@MainActor
struct ChartPageModelTests {
    @Test("the page opens on the chart of the tapped row, silently")
    func opensOnTappedRowSilently() async {
        let fakes = ListFakes()
        let model = createModel(fakes)
        await letTasksRun()

        #expect(model.chart.instrument == novartis)
        #expect(model.reader.cursorIndex == 1)
        #expect(model.reader.statusText == "Novartis ausgewählt")
        #expect(fakes.speaker.spokenTexts.isEmpty)
    }

    @Test("Nächste shows the next chart silently")
    func nextShowsNextChartSilently() async {
        let fakes = ListFakes()
        let model = createModel(fakes)

        model.reader.showNext()
        await model.reader.waitForSpeech()

        #expect(model.chart.instrument == roche)
        #expect(model.lastStep == .next)
        #expect(fakes.speaker.spokenTexts.isEmpty)
    }

    @Test("the next track of the AirPods shows the next chart and reads it")
    func nextTrackShowsAndReadsNextChart() async {
        let fakes = ListFakes()
        let model = createModel(fakes)

        model.reader.showNext(readsRow: true)
        await model.reader.waitForSpeech()

        #expect(model.chart.instrument == roche)
        #expect(fakes.speaker.spokenTexts == ["Roche, 1 Jahr, 65, plus 62,5 Prozent."])
    }

    @Test("Vorherige shows the chart before and moves to the left")
    func previousShowsChartBefore() async {
        let fakes = ListFakes()
        let model = createModel(fakes)

        model.reader.showPrevious()
        await model.reader.waitForSpeech()

        #expect(model.chart.instrument == nestle)
        #expect(model.lastStep == .previous)
    }

    @Test("Vorherige on the first chart says „Anfang der Liste.“ and keeps the chart")
    func previousOnFirstChartSaysStart() async {
        let fakes = ListFakes()
        let model = createModel(fakes, shown: nestle)

        model.reader.showPrevious()
        await model.reader.waitForSpeech()

        #expect(model.chart.instrument == nestle)
        #expect(fakes.speaker.spokenTexts == ["Anfang der Liste."])
    }

    @Test("the next chart keeps the chosen range")
    func nextChartKeepsRange() async {
        let fakes = ListFakes()
        let model = createModel(fakes)
        model.select(.fiveYears)

        model.reader.showNext()
        await model.reader.waitForSpeech()

        #expect(model.chart.range == .fiveYears)
    }

    @Test("a new range shows its part of the history silently")
    func newRangeIsSilent() async {
        let fakes = ListFakes()
        let model = createModel(fakes)

        model.select(.fiveYears)
        await model.reader.waitForSpeech()

        #expect(model.chart.range == .fiveYears)
        #expect(fakes.speaker.spokenTexts.isEmpty)
    }

    @Test("a new range during Vorlesen reads the chart again with its new change")
    func newRangeDuringReadingReadsChartAgain() async {
        let fakes = ListFakes(holdsSpeech: true)
        let model = createModel(fakes)
        model.reader.startReading()
        await waitUntil { fakes.speaker.isSpeaking }

        model.select(.fiveYears)
        await waitUntil { fakes.speaker.spokenTexts.count == 2 }

        #expect(fakes.speaker.spokenTexts.last == "Novartis, 5 Jahre, 65, plus 550,0 Prozent.")
    }

    @Test("a chart without a stored history reads its text after the fetch")
    func chartWithoutHistoryReadsAfterFetch() async {
        let fakes = ListFakes()
        let model = createModel(fakes, storedSymbols: [novartis.symbol])

        model.reader.showNext(readsRow: true)
        await model.reader.waitForSpeech()

        #expect(fakes.speaker.spokenTexts == ["Roche, 1 Jahr, 65, plus 62,5 Prozent."])
    }

    @Test("a chart whose fetch fails says that it has no history")
    func failedFetchSaysNoHistory() async {
        let fakes = ListFakes()
        let model = createModel(fakes, storedSymbols: [novartis.symbol], fetcher: FixedFetcher(error: .notFound))

        model.reader.showNext(readsRow: true)
        await model.reader.waitForSpeech()

        #expect(fakes.speaker.spokenTexts == ["Roche, kein Verlauf."])
    }

    @Test("Vorlesen reads only the shown chart and stays on it")
    func readingReadsOnlyShownChart() async {
        let fakes = ListFakes()
        let model = createModel(fakes)

        model.reader.startReading()
        await model.reader.waitForSpeech()

        #expect(fakes.speaker.spokenTexts == ["Novartis, 1 Jahr, 65, plus 62,5 Prozent."])
        #expect(fakes.sleeper.pauses.isEmpty)
        #expect(model.chart.instrument == novartis)
        #expect(model.reader.isReading == false)
    }

    @Test("Nächste during Vorlesen reads the next chart and then stops")
    func nextDuringReadingReadsNextChartAndStops() async {
        let fakes = ListFakes(holdsSpeech: true)
        let model = createModel(fakes, shown: nestle)
        model.reader.startReading()
        await waitUntil { fakes.speaker.isSpeaking }

        model.reader.showNext()
        await waitUntil { fakes.speaker.spokenTexts.count == 2 }
        fakes.speaker.finishSpeech()
        await model.reader.waitForSpeech()

        #expect(model.chart.instrument == novartis)
        #expect(fakes.speaker.spokenTexts.count == 2)
        #expect(model.reader.isReading == false)
    }

    @Test("a close stops the voice and Vorlesen")
    func closeStopsVoice() async {
        let fakes = ListFakes(holdsSpeech: true)
        let model = createModel(fakes)
        model.reader.startReading()
        await waitUntil { fakes.speaker.isSpeaking }

        model.close()

        #expect(model.reader.isReading == false)
        #expect(fakes.speaker.isSpeaking == false)
    }
}
