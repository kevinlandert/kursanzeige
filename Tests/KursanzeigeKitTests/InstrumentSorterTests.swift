import Testing
import Foundation
@testable import KursanzeigeKit

struct InstrumentSorterTests {

    private func row(_ name: String, price: Double? = nil, day: Double? = nil, oneMonth: Double? = nil, threeMonth: Double? = nil, oneYear: Double? = nil, ytd: Double? = nil) -> InstrumentRow {
        InstrumentRow(
            instrument: Instrument(symbol: name.uppercased(), name: name, group: .switzerland),
            price: price,
            asOf: nil,
            dayChangePercent: day,
            threeMonthChangePercent: threeMonth,
            oneYearChangePercent: oneYear,
            yearToDateChangePercent: ytd,
            oneMonthChangePercent: oneMonth
        )
    }

    @Test func sortsByNameAscending() {
        let rows = [row("Zürich"), row("Adecco"), row("Nestlé")]
        let sorted = InstrumentSorter.sort(rows, by: SortState(column: .name, ascending: true))
        #expect(sorted.map(\.instrument.name) == ["Adecco", "Nestlé", "Zürich"])
    }

    @Test func sortsByNameDescending() {
        let rows = [row("Zürich"), row("Adecco"), row("Nestlé")]
        let sorted = InstrumentSorter.sort(rows, by: SortState(column: .name, ascending: false))
        #expect(sorted.map(\.instrument.name) == ["Zürich", "Nestlé", "Adecco"])
    }

    @Test func sortsByPriceAscendingWithNilsLast() {
        let rows = [row("B", price: 50), row("A", price: nil), row("C", price: 10)]
        let sorted = InstrumentSorter.sort(rows, by: SortState(column: .price, ascending: true))
        #expect(sorted.map(\.instrument.name) == ["C", "B", "A"])
    }

    @Test func sortsByPriceDescendingWithNilsStillLast() {
        let rows = [row("B", price: 50), row("A", price: nil), row("C", price: 10)]
        let sorted = InstrumentSorter.sort(rows, by: SortState(column: .price, ascending: false))
        #expect(sorted.map(\.instrument.name) == ["B", "C", "A"])
    }

    @Test func sortsByDayChangeAscending() {
        let rows = [row("Up", day: 5), row("Down", day: -3), row("Flat", day: 0)]
        let sorted = InstrumentSorter.sort(rows, by: SortState(column: .day, ascending: true))
        #expect(sorted.map(\.instrument.name) == ["Down", "Flat", "Up"])
    }

    @Test func allNilValuesKeepStableNameOrder() {
        let rows = [row("Zürich"), row("Adecco")]
        let sorted = InstrumentSorter.sort(rows, by: SortState(column: .price, ascending: true))
        // Both nil -> falls back to name order.
        #expect(sorted.map(\.instrument.name) == ["Adecco", "Zürich"])
    }

    @Test func oneYearColumnSortsByTrailingOneYearByDefault() {
        let rows = [row("A", oneYear: -5, ytd: 20), row("B", oneYear: 10, ytd: -3)]
        let sorted = InstrumentSorter.sort(rows, by: SortState(column: .oneYear, ascending: true))
        #expect(sorted.map(\.instrument.name) == ["A", "B"])
    }

    @Test func oneYearColumnSortsByYearToDateWhenThatModeIsActive() {
        let rows = [row("A", oneYear: -5, ytd: 20), row("B", oneYear: 10, ytd: -3)]
        let sorted = InstrumentSorter.sort(rows, by: SortState(column: .oneYear, ascending: true), oneYearMode: .yearToDate)
        // Ascending by YTD: B (-3) before A (20), the reverse of the trailing-1Y order above.
        #expect(sorted.map(\.instrument.name) == ["B", "A"])
    }

    @Test func threeMonthColumnSortsByThreeMonthByDefault() {
        let rows = [row("A", oneMonth: 10, threeMonth: -5), row("B", oneMonth: -3, threeMonth: 20)]
        let sorted = InstrumentSorter.sort(rows, by: SortState(column: .threeMonth, ascending: true))
        #expect(sorted.map(\.instrument.name) == ["A", "B"])
    }

    @Test func threeMonthColumnSortsByOneMonthWhenThatRangeModeIsActive() {
        let rows = [row("A", oneMonth: 10, threeMonth: -5), row("B", oneMonth: -3, threeMonth: 20)]
        let sorted = InstrumentSorter.sort(rows, by: SortState(column: .threeMonth, ascending: true), rangeMode: .oneMonth)
        // Ascending by 1-month: B (-3) before A (10), the reverse of the 3-month order above.
        #expect(sorted.map(\.instrument.name) == ["B", "A"])
    }
}
