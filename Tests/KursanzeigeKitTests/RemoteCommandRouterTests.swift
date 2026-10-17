import Testing
@testable import KursanzeigeKit

@MainActor
private func createReader(_ fakes: ListFakes, list: String, titles: [String]) -> ListReader {
    let rows = titles.map { title in SpokenRow(id: title, title: title, speech: { "\(title)." }) }
    return ListReader(rows: rows, list: list, services: fakes.services)
}

@Suite("RemoteCommandRouter")
@MainActor
struct RemoteCommandRouterTests {
    @Test("on the table, the next track moves the table cursor")
    func nextTrackMovesTableCursor() async {
        let fakes = ListFakes()
        let table = createReader(fakes, list: "Schweiz", titles: ["Nestlé", "Novartis"])
        let router = RemoteCommandRouter(tableReader: table)

        let isDone = router.performCommand(.nextTrack)
        await table.waitForSpeech()

        #expect(isDone)
        #expect(table.cursorIndex == 1)
        #expect(fakes.speaker.spokenTexts == ["Novartis."])
    }

    @Test("play starts Vorlesen, pause stops it, and the toggle switches it")
    func playPauseAndToggleControlReading() async {
        let fakes = ListFakes(holdsSpeech: true)
        let table = createReader(fakes, list: "Schweiz", titles: ["Nestlé", "Novartis"])
        let router = RemoteCommandRouter(tableReader: table)

        router.performCommand(.play)
        #expect(table.isReading)
        router.performCommand(.pause)
        #expect(table.isReading == false)
        router.performCommand(.togglePlayPause)
        #expect(table.isReading)
        router.performCommand(.togglePlayPause)
        #expect(table.isReading == false)
    }

    @Test("on the chart page, the commands go to the chart reader and not to the table")
    func chartPageGetsCommands() async {
        let fakes = ListFakes()
        let table = createReader(fakes, list: "Schweiz", titles: ["Nestlé", "Novartis"])
        let chart = createReader(fakes, list: "Schweiz", titles: ["Nestlé", "Novartis"])
        let router = RemoteCommandRouter(tableReader: table)

        router.showChart(chart)
        router.performCommand(.nextTrack)
        await chart.waitForSpeech()

        #expect(chart.cursorIndex == 1)
        #expect(table.cursorIndex == 0)
    }

    @Test("after the chart page closes, the commands go to the table again")
    func closedChartGivesCommandsToTable() async {
        let fakes = ListFakes()
        let table = createReader(fakes, list: "Schweiz", titles: ["Nestlé", "Novartis"])
        let chart = createReader(fakes, list: "Schweiz", titles: ["Nestlé", "Novartis"])
        let router = RemoteCommandRouter(tableReader: table)
        router.showChart(chart)

        router.showTable()
        router.performCommand(.nextTrack)
        await table.waitForSpeech()

        #expect(table.cursorIndex == 1)
    }

    @Test("while the settings show, the commands do nothing")
    func settingsIgnoreCommands() async {
        let fakes = ListFakes()
        let table = createReader(fakes, list: "Schweiz", titles: ["Nestlé", "Novartis"])
        let router = RemoteCommandRouter(tableReader: table)

        router.showSettings()
        let isDone = router.performCommand(.nextTrack)
        await letTasksRun()

        #expect(isDone == false)
        #expect(table.cursorIndex == 0)
        #expect(fakes.speaker.spokenTexts.isEmpty)
    }

    @Test("the lock screen shows the cursor row of the visible page")
    func nowPlayingFollowsVisiblePage() {
        let fakes = ListFakes()
        let table = createReader(fakes, list: "Schweiz", titles: ["Nestlé", "Novartis"])
        let chart = createReader(fakes, list: "Schweiz", titles: ["Nestlé", "Novartis"])
        chart.placeCursor(at: 1)
        let router = RemoteCommandRouter(tableReader: table)

        #expect(router.nowPlayingItem.title == "Nestlé")
        router.showChart(chart)
        #expect(router.nowPlayingItem.title == "Novartis")
        router.showSettings()
        #expect(router.nowPlayingItem.title == "Nestlé")
    }
}
