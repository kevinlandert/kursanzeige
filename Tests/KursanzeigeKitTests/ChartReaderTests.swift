import Testing
@testable import KursanzeigeKit

/// Records what the reader asks for, in order.
@MainActor
private final class RecordingSpeaker: Speaking {
    private(set) var calls: [String] = []

    func speak(_ text: String) { calls.append("speak: \(text)") }
    func stop() { calls.append("stop") }
}

@MainActor
private func createReader() -> (ChartReader, RecordingSpeaker) {
    let speaker = RecordingSpeaker()
    return (ChartReader(speaker: speaker), speaker)
}

@Suite("ChartReader")
@MainActor
struct ChartReaderTests {
    @Test("a new reader is off and says nothing")
    func newReaderIsOff() {
        let (reader, speaker) = createReader()

        #expect(reader.isOn == false)
        #expect(speaker.calls.isEmpty)
    }

    @Test("a tap when off reads the shown chart")
    func tapWhenOffReadsShownChart() {
        let (reader, speaker) = createReader()

        reader.toggle(shownText: "Dow Jones, 1 Jahr")

        #expect(reader.isOn)
        #expect(speaker.calls == ["stop", "speak: Dow Jones, 1 Jahr"])
    }

    @Test("a tap when on stops the voice")
    func tapWhenOnStopsVoice() {
        let (reader, speaker) = createReader()
        reader.toggle(shownText: "Dow Jones, 1 Jahr")

        reader.toggle(shownText: "Dow Jones, 1 Jahr")

        #expect(reader.isOn == false)
        #expect(speaker.calls.last == "stop")
    }

    @Test("when on, a new chart stops the old text and reads the new one")
    func newChartIsReadWhenOn() {
        let (reader, speaker) = createReader()
        reader.toggle(shownText: "Dow Jones, 1 Jahr")

        reader.readIfOn("DAX, 1 Jahr")

        #expect(speaker.calls.suffix(2) == ["stop", "speak: DAX, 1 Jahr"])
    }

    @Test("when on, a new chart without data stops the old text")
    func newChartWithoutDataStopsOldText() {
        let (reader, speaker) = createReader()
        reader.toggle(shownText: "Dow Jones, 1 Jahr")

        reader.readIfOn(nil)

        #expect(reader.isOn)
        #expect(speaker.calls.last == "stop")
    }

    @Test("when off, a new chart is not read")
    func newChartIsNotReadWhenOff() {
        let (reader, speaker) = createReader()

        reader.readIfOn("DAX, 1 Jahr")

        #expect(speaker.calls.isEmpty)
    }

    @Test("a tap before the chart has data reads the chart when the data arrives")
    func chartWithoutDataIsReadWhenDataComes() {
        let (reader, speaker) = createReader()

        reader.toggle(shownText: nil)
        reader.readIfOn("DAX, 1 Jahr")

        #expect(reader.isOn)
        #expect(speaker.calls.last == "speak: DAX, 1 Jahr")
        #expect(speaker.calls.filter { $0.hasPrefix("speak") }.count == 1)
    }

    @Test("a closed chart page stops the voice and turns the reader off")
    func closedChartPageStopsVoiceAndTurnsOff() {
        let (reader, speaker) = createReader()
        reader.toggle(shownText: "Dow Jones, 1 Jahr")

        reader.turnOff()

        #expect(reader.isOn == false)
        #expect(speaker.calls.last == "stop")
    }
}
