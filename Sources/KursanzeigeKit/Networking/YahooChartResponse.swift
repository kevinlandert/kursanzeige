import Foundation

/// Mirrors the subset of Yahoo Finance's `v8/finance/chart/<symbol>` JSON
/// response this app actually uses. The endpoint is unofficial (the same
/// one the Python `yfinance` library scrapes), so decoding is deliberately
/// forgiving: unrecognized fields are ignored, and a `null` in the close
/// array (Yahoo emits these for non-trading days within the requested
/// range) decodes to `nil` rather than failing the whole response.
struct YahooChartResponse: Decodable {
    struct Chart: Decodable {
        let result: [Result]?
        let error: ChartError?
    }
    struct ChartError: Decodable {
        let code: String
        let description: String
    }
    struct Result: Decodable {
        let meta: Meta
        let timestamp: [Int]?
        let indicators: Indicators
    }
    struct Meta: Decodable {
        let symbol: String
        let currency: String?
        /// E.g. "EQUITY", "ETF", "INDEX", "CURRENCY" or "FUTURE".
        let instrumentType: String?
        let regularMarketPrice: Double?
    }
    struct Indicators: Decodable {
        let quote: [Quote]
    }
    struct Quote: Decodable {
        let close: [Double?]
    }

    let chart: Chart
}

extension YahooChartResponse {
    enum ConversionError: Error {
        case apiError(String)
        case missingResult
    }

    /// Converts the decoded response into the `ClosePoint` series the
    /// calculator expects: `null` closes and their matching timestamps are
    /// dropped, and points are left in the order Yahoo returned them
    /// (`PerformanceCalculator` sorts defensively regardless). A price in
    /// a sub unit, e.g. pence, changes to the main unit (see `PriceCurrency`).
    func fetchedCloses() throws -> FetchedCloses {
        if let error = chart.error {
            throw ConversionError.apiError(error.description)
        }
        guard let result = chart.result?.first,
              let timestamps = result.timestamp,
              let closes = result.indicators.quote.first?.close
        else {
            throw ConversionError.missingResult
        }
        let currency = PriceCurrency(instrumentType: result.meta.instrumentType, yahooCurrency: result.meta.currency)
        let points = zip(timestamps, closes).compactMap { timestamp, close -> ClosePoint? in
            guard let close else { return nil }
            return ClosePoint(date: Date(timeIntervalSince1970: TimeInterval(timestamp)), close: close / currency.priceDivisor)
        }
        return FetchedCloses(closes: points, currency: currency.shownCurrency)
    }
}
