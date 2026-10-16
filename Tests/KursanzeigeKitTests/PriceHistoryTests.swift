import Testing
import Foundation
@testable import KursanzeigeKit

private let utcCalendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
}()

private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
    utcCalendar.date(from: DateComponents(year: year, month: month, day: day))!
}

private func close(_ year: Int, _ month: Int, _ day: Int, _ value: Double) -> ClosePoint {
    ClosePoint(date: date(year, month, day), close: value)
}

/// One close per weekday up to `end`, rising by one each day -- enough
/// history for every range, with a different value on every date. No
/// closes on weekends, as on a real exchange.
private func createWeekdayCloses(endingAt end: Date, days: Int) -> [ClosePoint] {
    (0..<days)
        .map { offset in utcCalendar.date(byAdding: .day, value: -offset, to: end)! }
        .filter { !utcCalendar.isDateInWeekend($0) }
        .enumerated()
        .map { index, date in ClosePoint(date: date, close: 10_000 - Double(index)) }
}

@Suite("PriceHistory")
struct PriceHistoryTests {
    @Test("closes are kept oldest to newest")
    func closesAreSortedByDate() {
        let history = PriceHistory(closes: [close(2026, 10, 15, 3), close(2026, 10, 13, 1), close(2026, 10, 14, 2)], fetchedAt: date(2026, 10, 15))

        #expect(history.closes.map(\.close) == [1, 2, 3])
    }

    @Test("a three-month range starts at the last close on or before the range start")
    func threeMonthRangeStartsAtLastCloseBeforeStart() {
        let closes = [
            close(2026, 7, 10, 1),
            close(2026, 7, 14, 2),
            close(2026, 7, 16, 3),
            close(2026, 8, 1, 4),
            close(2026, 10, 15, 5),
        ]
        let history = PriceHistory(closes: closes, fetchedAt: date(2026, 10, 15))

        let shown = history.closes(in: .threeMonths, calendar: utcCalendar)

        #expect(shown.map(\.close) == [2, 3, 4, 5])
    }

    @Test("a range longer than the history shows all closes")
    func rangeLongerThanHistoryShowsAllCloses() {
        let closes = [close(2026, 1, 5, 1), close(2026, 10, 15, 2)]
        let history = PriceHistory(closes: closes, fetchedAt: date(2026, 10, 15))

        let shown = history.closes(in: .fiveYears, calendar: utcCalendar)

        #expect(shown.map(\.close) == [1, 2])
    }

    @Test("the one-year chart change equals the table's one-year change")
    func oneYearChartChangeEqualsTableChange() throws {
        let fetchedOnSunday = date(2026, 10, 18)
        let history = PriceHistory(closes: createWeekdayCloses(endingAt: fetchedOnSunday, days: 2_000), fetchedAt: fetchedOnSunday)
        let tableChange = try #require(PerformanceCalculator.changes(closes: history.closes, asOf: fetchedOnSunday, calendar: utcCalendar).oneYearChangePercent)

        let shown = history.closes(in: .oneYear, calendar: utcCalendar)
        let chartChange = (shown.last!.close - shown.first!.close) / shown.first!.close * 100

        #expect(chartChange == tableChange)
    }

    @Test("the three-month chart change equals the table's three-month change")
    func threeMonthChartChangeEqualsTableChange() throws {
        let fetchedOnSunday = date(2026, 10, 18)
        let history = PriceHistory(closes: createWeekdayCloses(endingAt: fetchedOnSunday, days: 2_000), fetchedAt: fetchedOnSunday)
        let tableChange = try #require(PerformanceCalculator.changes(closes: history.closes, asOf: fetchedOnSunday, calendar: utcCalendar).threeMonthChangePercent)

        let shown = history.closes(in: .threeMonths, calendar: utcCalendar)
        let chartChange = (shown.last!.close - shown.first!.close) / shown.first!.close * 100

        #expect(chartChange == tableChange)
    }

    @Test("the one-month chart change equals the table's one-month change")
    func oneMonthChartChangeEqualsTableChange() throws {
        let fetchedOnSunday = date(2026, 10, 18)
        let history = PriceHistory(closes: createWeekdayCloses(endingAt: fetchedOnSunday, days: 2_000), fetchedAt: fetchedOnSunday)
        let tableChange = try #require(PerformanceCalculator.changes(closes: history.closes, asOf: fetchedOnSunday, calendar: utcCalendar).oneMonthChangePercent)

        let shown = history.closes(in: .oneMonth, calendar: utcCalendar)
        let chartChange = (shown.last!.close - shown.first!.close) / shown.first!.close * 100

        #expect(chartChange == tableChange)
    }

    @Test("the range buttons go from the shortest to the longest range")
    func rangesAreOrderedShortestFirst() {
        #expect(ChartRange.allCases == [.oneMonth, .threeMonths, .oneYear, .fiveYears])
    }

    @Test("a history keeps its currency in the stored file")
    func historyKeepsCurrencyInFile() throws {
        let history = PriceHistory(closes: [], currency: "GBP", fetchedAt: date(2026, 10, 15))

        let decoded = try JSONDecoder().decode(PriceHistory.self, from: JSONEncoder().encode(history))

        #expect(decoded.currency == "GBP")
    }

    @Test("a file from before the currency gives a history without a currency")
    func fileWithoutCurrencyGivesNoCurrency() throws {
        let json: [String: Any] = ["closes": [], "fetchedAt": date(2026, 10, 15).timeIntervalSinceReferenceDate]

        let decoded = try JSONDecoder().decode(PriceHistory.self, from: JSONSerialization.data(withJSONObject: json))

        #expect(decoded.currency == nil)
    }

    @Test("a decoded history is sorted, even when the file is not")
    func decodedHistoryIsSorted() throws {
        let unsorted = PriceHistory(closes: [], fetchedAt: date(2026, 10, 15))
        var json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(unsorted)) as! [String: Any]
        json["closes"] = [
            ["date": date(2026, 10, 14).timeIntervalSinceReferenceDate, "close": 2.0],
            ["date": date(2026, 10, 13).timeIntervalSinceReferenceDate, "close": 1.0],
        ]

        let decoded = try JSONDecoder().decode(PriceHistory.self, from: JSONSerialization.data(withJSONObject: json))

        #expect(decoded.closes.map(\.close) == [1, 2])
    }
}
