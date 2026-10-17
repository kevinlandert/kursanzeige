/// What the voice reads for a table row: the chosen columns, and the
/// periods that the two range columns show now.
public struct TableSpeechSettings: Equatable, Sendable {
    public let columns: SpokenColumns
    public let rangeMode: RangeMode
    public let oneYearMode: OneYearMode

    public static let standard = TableSpeechSettings(columns: .standard, rangeMode: .threeMonth, oneYearMode: .trailing)

    public init(columns: SpokenColumns, rangeMode: RangeMode, oneYearMode: OneYearMode) {
        self.columns = columns
        self.rangeMode = rangeMode
        self.oneYearMode = oneYearMode
    }
}
