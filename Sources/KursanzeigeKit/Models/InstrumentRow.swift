import Foundation

/// One row of the table: a fixed instrument paired with its latest computed
/// performance. This is the unit the table sorts, colors, and caches.
public struct InstrumentRow: Codable, Equatable, Identifiable, Sendable {
    public let instrument: Instrument
    public let price: Double?
    public let asOf: Date?
    public let dayChangePercent: Double?
    public let threeMonthChangePercent: Double?
    public let oneYearChangePercent: Double?
    public let yearToDateChangePercent: Double?
    public let oneMonthChangePercent: Double?
    /// Only for the spoken table, not shown. See `PriceUnitRule`.
    public let unit: PriceUnit?

    public var id: String { instrument.symbol }

    public init(
        instrument: Instrument,
        price: Double?,
        asOf: Date?,
        dayChangePercent: Double?,
        threeMonthChangePercent: Double?,
        oneYearChangePercent: Double?,
        yearToDateChangePercent: Double? = nil,
        oneMonthChangePercent: Double? = nil,
        unit: PriceUnit? = nil
    ) {
        self.instrument = instrument
        self.price = price
        self.asOf = asOf
        self.dayChangePercent = dayChangePercent
        self.threeMonthChangePercent = threeMonthChangePercent
        self.oneYearChangePercent = oneYearChangePercent
        self.yearToDateChangePercent = yearToDateChangePercent
        self.oneMonthChangePercent = oneMonthChangePercent
        self.unit = unit
    }

    /// A row for an instrument with no data yet (before the first successful fetch).
    static func empty(_ instrument: Instrument) -> InstrumentRow {
        InstrumentRow(
            instrument: instrument,
            price: nil,
            asOf: nil,
            dayChangePercent: nil,
            threeMonthChangePercent: nil,
            oneYearChangePercent: nil,
            yearToDateChangePercent: nil,
            oneMonthChangePercent: nil
        )
    }

    /// Combines a fixed instrument with freshly computed performance changes.
    static func combining(_ instrument: Instrument, _ changes: PerformanceChanges, unit: PriceUnit?) -> InstrumentRow {
        InstrumentRow(
            instrument: instrument,
            price: changes.latestPrice,
            asOf: changes.asOf,
            dayChangePercent: changes.dayChangePercent,
            threeMonthChangePercent: changes.threeMonthChangePercent,
            oneYearChangePercent: changes.oneYearChangePercent,
            yearToDateChangePercent: changes.yearToDateChangePercent,
            oneMonthChangePercent: changes.oneMonthChangePercent,
            unit: unit
        )
    }
}
