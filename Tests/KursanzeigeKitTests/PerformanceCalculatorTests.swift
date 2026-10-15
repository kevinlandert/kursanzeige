import Testing
import Foundation
@testable import KursanzeigeKit

struct PerformanceCalculatorTests {

    private let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Europe/Zurich")!
        return cal
    }()

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d))!
    }

    // MARK: - Empty / minimal input

    @Test func emptySeriesProducesAllNil() {
        let result = PerformanceCalculator.changes(closes: [], asOf: date(2026, 9, 10), calendar: calendar)
        #expect(result == .empty)
    }

    @Test func singlePointHasPriceButNoChanges() {
        let closes = [ClosePoint(date: date(2026, 9, 10), close: 100)]
        let result = PerformanceCalculator.changes(closes: closes, asOf: date(2026, 9, 10), calendar: calendar)
        #expect(result.latestPrice == 100)
        #expect(result.asOf == date(2026, 9, 10))
        #expect(result.dayChangePercent == nil)
        #expect(result.oneMonthChangePercent == nil)
        #expect(result.threeMonthChangePercent == nil)
        #expect(result.oneYearChangePercent == nil)
    }

    // MARK: - Day change

    @Test func dayChangeUsesImmediatelyPrecedingClose() {
        let closes = [
            ClosePoint(date: date(2026, 9, 8), close: 100),
            ClosePoint(date: date(2026, 9, 9), close: 110),
        ]
        let result = PerformanceCalculator.changes(closes: closes, asOf: date(2026, 9, 9), calendar: calendar)
        #expect(result.latestPrice == 110)
        // (110 - 100) / 100 * 100 = 10%
        #expect(approximatelyEqual(result.dayChangePercent, 10))
    }

    @Test func dayChangeIsNilWithOnlyOnePriorPointMissing() {
        // Only one data point total -> no "previous" close to compare against.
        let closes = [ClosePoint(date: date(2026, 9, 9), close: 110)]
        let result = PerformanceCalculator.changes(closes: closes, asOf: date(2026, 9, 9), calendar: calendar)
        #expect(result.dayChangePercent == nil)
    }

    @Test func negativeDayChangeIsComputedCorrectly() {
        let closes = [
            ClosePoint(date: date(2026, 9, 8), close: 100),
            ClosePoint(date: date(2026, 9, 9), close: 90),
        ]
        let result = PerformanceCalculator.changes(closes: closes, asOf: date(2026, 9, 9), calendar: calendar)
        #expect(approximatelyEqual(result.dayChangePercent, -10))
    }

    // MARK: - 1-month, 3-month and 1-year change with full history

    @Test func oneMonthThreeMonthAndOneYearChangeUseClosestPriorClose() {
        var closes: [ClosePoint] = []
        // Build a daily series (business days only) from 2025-09-01 through 2026-09-10,
        // price rising by 0.1 per day starting at 100.
        var d = date(2025, 9, 1)
        var price = 100.0
        let end = date(2026, 9, 10)
        while d <= end {
            let weekday = calendar.component(.weekday, from: d)
            if weekday != 1 && weekday != 7 { // skip weekends
                closes.append(ClosePoint(date: d, close: price))
                price += 0.1
            }
            d = calendar.date(byAdding: .day, value: 1, to: d)!
        }

        let result = PerformanceCalculator.changes(closes: closes, asOf: end, calendar: calendar)
        #expect(result.latestPrice != nil)
        #expect(result.oneMonthChangePercent != nil)
        #expect(result.threeMonthChangePercent != nil)
        #expect(result.oneYearChangePercent != nil)
        #expect(result.yearToDateChangePercent != nil)
        // Since price only ever rises, all changes must be positive.
        #expect(result.oneMonthChangePercent! > 0)
        #expect(result.threeMonthChangePercent! > 0)
        #expect(result.oneYearChangePercent! > 0)
        #expect(result.yearToDateChangePercent! > 0)
        // More time to rise -> larger change: 1-year > 3-month > 1-month.
        #expect(result.oneYearChangePercent! > result.threeMonthChangePercent!)
        #expect(result.threeMonthChangePercent! > result.oneMonthChangePercent!)
    }

    @Test func oneMonthChangeIsNilWhenHistoryTooShort() {
        // Only 10 days of history available -- not enough to reach back 1 month.
        let closes = [
            ClosePoint(date: date(2026, 9, 1), close: 100),
            ClosePoint(date: date(2026, 9, 10), close: 105),
        ]
        let result = PerformanceCalculator.changes(closes: closes, asOf: date(2026, 9, 10), calendar: calendar)
        #expect(result.dayChangePercent != nil)
        #expect(result.oneMonthChangePercent == nil)
    }

    // MARK: - Year-to-date change

    @Test func yearToDateUsesLastCloseOfPriorYear() {
        let closes = [
            ClosePoint(date: date(2025, 12, 30), close: 90),  // last trading day of 2025
            ClosePoint(date: date(2026, 1, 2), close: 92),
            ClosePoint(date: date(2026, 9, 10), close: 99),
        ]
        let result = PerformanceCalculator.changes(closes: closes, asOf: date(2026, 9, 10), calendar: calendar)
        // (99 - 90) / 90 * 100
        #expect(approximatelyEqual(result.yearToDateChangePercent, (99.0 - 90.0) / 90.0 * 100.0))
    }

    @Test func yearToDateSkipsNewYearsDayHolidayToLastDecemberClose() {
        // Jan 1st is a market holiday everywhere -- there is never a close
        // point for it, so the calculator must fall back to Dec 31 (or the
        // closest trading day before it), the same way it already does for
        // weekends.
        let closes = [
            ClosePoint(date: date(2025, 12, 31), close: 200),
            ClosePoint(date: date(2026, 1, 5), close: 220),
        ]
        let result = PerformanceCalculator.changes(closes: closes, asOf: date(2026, 1, 5), calendar: calendar)
        #expect(approximatelyEqual(result.yearToDateChangePercent, (220.0 - 200.0) / 200.0 * 100.0))
    }

    @Test func yearToDateIsNilWhenNoDataFromBeforeThisYear() {
        // History only starts in February of the current year -- there is
        // no prior-year close to anchor YTD to.
        let closes = [
            ClosePoint(date: date(2026, 2, 1), close: 50),
            ClosePoint(date: date(2026, 9, 10), close: 55),
        ]
        let result = PerformanceCalculator.changes(closes: closes, asOf: date(2026, 9, 10), calendar: calendar)
        #expect(result.yearToDateChangePercent == nil)
    }

    @Test func threeMonthChangeIsNilWhenHistoryTooShort() {
        // Only 1 month of history available.
        let closes = [
            ClosePoint(date: date(2026, 8, 10), close: 100),
            ClosePoint(date: date(2026, 9, 10), close: 105),
        ]
        let result = PerformanceCalculator.changes(closes: closes, asOf: date(2026, 9, 10), calendar: calendar)
        #expect(result.dayChangePercent != nil) // has an immediately preceding point
        // Exactly 1 month of history is enough for the 1-month change.
        #expect(approximatelyEqual(result.oneMonthChangePercent, 5))
        #expect(result.threeMonthChangePercent == nil)
        #expect(result.oneYearChangePercent == nil)
    }

    @Test func referenceTargetFallsOnWeekendPicksClosestPriorTradingDay() {
        // FX-style series: reference date for "3 months ago" lands on a Saturday;
        // the calculator must fall back to the closest prior close, not skip it.
        let closes = [
            ClosePoint(date: date(2026, 6, 5), close: 50),  // Friday, closest before the weekend target
            ClosePoint(date: date(2026, 6, 8), close: 52),  // Monday after
            ClosePoint(date: date(2026, 9, 10), close: 60),
        ]
        // 2026-09-10 minus 3 months = 2026-06-10 (a Wednesday) -- adjust test to
        // land the target on a weekend instead: use asOf 2026-09-06 (Sunday) -> 3mo ago = 2026-06-06 (Saturday).
        let asOf = date(2026, 9, 6)
        let closesForWeekendCase = [
            ClosePoint(date: date(2026, 6, 5), close: 50),
            ClosePoint(date: date(2026, 6, 8), close: 52),
            ClosePoint(date: date(2026, 9, 4), close: 60),
        ]
        let result = PerformanceCalculator.changes(closes: closesForWeekendCase, asOf: asOf, calendar: calendar)
        // 3 months before 2026-09-06 is 2026-06-06 (Saturday) -> closest prior close is 2026-06-05 (50).
        #expect(approximatelyEqual(result.threeMonthChangePercent, (60.0 - 50.0) / 50.0 * 100.0))
        _ = closes // silence unused-variable warning for the illustrative first series
    }

    @Test func zeroPercentChangeIsExactlyZeroNotNil() {
        let closes = [
            ClosePoint(date: date(2026, 9, 8), close: 100),
            ClosePoint(date: date(2026, 9, 9), close: 100),
        ]
        let result = PerformanceCalculator.changes(closes: closes, asOf: date(2026, 9, 9), calendar: calendar)
        #expect(result.dayChangePercent == 0)
    }

    @Test func unsortedInputIsSortedBeforeComputing() {
        let closes = [
            ClosePoint(date: date(2026, 9, 9), close: 110),
            ClosePoint(date: date(2026, 9, 8), close: 100),
        ]
        let result = PerformanceCalculator.changes(closes: closes, asOf: date(2026, 9, 9), calendar: calendar)
        #expect(approximatelyEqual(result.dayChangePercent, 10))
    }

    @Test func asOfDateAfterLastCloseUsesLastAvailableClose() {
        // Reference date is "now", which can be a day the market hasn't closed
        // for yet -- the latest available close should still be used.
        let closes = [
            ClosePoint(date: date(2026, 9, 8), close: 100),
            ClosePoint(date: date(2026, 9, 9), close: 105),
        ]
        let result = PerformanceCalculator.changes(closes: closes, asOf: date(2026, 9, 10, hour: 8), calendar: calendar)
        #expect(result.latestPrice == 105)
        #expect(result.asOf == date(2026, 9, 9))
    }
}

private func approximatelyEqual(_ a: Double?, _ b: Double, tolerance: Double = 0.0001) -> Bool {
    guard let a else { return false }
    return abs(a - b) < tolerance
}

private extension PerformanceCalculatorTests {
    func date(_ y: Int, _ m: Int, _ d: Int, hour: Int) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: hour))!
    }
}
