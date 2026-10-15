import Testing
import Foundation
@testable import KursanzeigeKit

private let firstDay = Date(timeIntervalSince1970: 1_600_000_000)

/// One close per day, with the value `closeOnDay` gives for each day.
private func createDailyCloses(days: Int, closeOnDay: (Int) -> Double) -> [ClosePoint] {
    (0..<days).map { day in
        ClosePoint(date: firstDay.addingTimeInterval(Double(day) * 86_400), close: closeOnDay(day))
    }
}

/// A wavy line with small daily noise, like a real price.
private func createNoisyCloses(days: Int) -> [ClosePoint] {
    createDailyCloses(days: days) { day in
        100 + 20 * sin(Double(day) / 60) + Double(day % 7) - 3
    }
}

@Suite("LineThinner")
struct LineThinnerTests {
    @Test("a line with no more closes than the maximum stays as it is")
    func shortLineStaysAsItIs() {
        let closes = createNoisyCloses(days: 150)

        #expect(LineThinner.thin(closes, toAtMost: 150) == closes)
    }

    @Test("a long line keeps no more closes than the maximum")
    func longLineKeepsAtMostTheMaximum() {
        let thinned = LineThinner.thin(createNoisyCloses(days: 1_260), toAtMost: 150)

        #expect(thinned.count <= 150)
        #expect(thinned.count >= 140)
    }

    @Test("a thinned line keeps the first and the last close")
    func thinnedLineKeepsFirstAndLastClose() {
        let closes = createNoisyCloses(days: 1_260)

        let thinned = LineThinner.thin(closes, toAtMost: 150)

        #expect(thinned.first == closes.first)
        #expect(thinned.last == closes.last)
    }

    @Test("a thinned line keeps the highest and the lowest close")
    func thinnedLineKeepsHighestAndLowestClose() {
        let closes = createNoisyCloses(days: 1_260)

        let thinned = LineThinner.thin(closes, toAtMost: 150)

        #expect(thinned.map(\.close).max() == closes.map(\.close).max())
        #expect(thinned.map(\.close).min() == closes.map(\.close).min())
    }

    @Test("a thinned line keeps a one-day drop that is not the lowest close")
    func thinnedLineKeepsOneDayDrop() {
        let closes = createDailyCloses(days: 1_260) { day in
            switch day {
            case 700: 50
            case 1_000: 30
            default: 100
            }
        }

        let thinned = LineThinner.thin(closes, toAtMost: 150)

        #expect(thinned.contains(closes[700]))
    }

    @Test("a thinned line has only real closes, oldest to newest")
    func thinnedLineHasOnlyRealClosesInDateOrder() {
        let closes = createNoisyCloses(days: 1_260)

        let thinned = LineThinner.thin(closes, toAtMost: 150)

        #expect(thinned.allSatisfy { closes.contains($0) })
        #expect(thinned.map(\.date) == thinned.map(\.date).sorted())
        #expect(Set(thinned.map(\.date)).count == thinned.count)
    }
}
