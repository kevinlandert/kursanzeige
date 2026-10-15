import Foundation

/// How many decimals a price shows, on screen and in speech. Currency
/// rates are quoted to 4 decimals, everything else to 2. A value of 1000
/// or more has none, in every group: an index level like 3601 gains no
/// information from cents.
public enum PricePrecision {
    public static func maximumFractionDigits(for value: Double, group: MarketGroup) -> Int {
        if abs(value) >= 1000 { return 0 }
        return group == .currencies ? 4 : 2
    }
}
