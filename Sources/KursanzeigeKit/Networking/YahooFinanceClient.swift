import Foundation

/// Fetches daily closes from Yahoo Finance's unofficial `v8/finance/chart`
/// endpoint -- the same one the Python `yfinance` library reads. There is
/// no official public API for this data; a normal `User-Agent` header is
/// required or Yahoo responds 429 to every request.
struct YahooFinanceClient: PriceFetching {
    private let session: URLSession
    private let range: String
    private let requestTimeout: TimeInterval

    /// Any browser-shaped UA works; Yahoo blocks the default `URLSession`
    /// UA string specifically, not real ones.
    private static let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"

    /// "5y" covers the table's columns and the longest chart range in one
    /// request per symbol. Yahoo limits the number of requests, not their
    /// size, so the longer range adds no risk of a 429.
    ///
    /// `requestTimeout` replaces the system default of 60 seconds. On a
    /// silent connection, the retries then start, and the user sees an
    /// error, after seconds instead of minutes.
    init(session: URLSession = .shared, range: String = "5y", requestTimeout: TimeInterval = 15) {
        self.session = session
        self.range = range
        self.requestTimeout = requestTimeout
    }

    func fetchCloses(for symbol: String) async throws -> [ClosePoint] {
        // Deliberately not `.urlPathAllowed`: that set is meant for encoding
        // a whole path, so it leaves "/" unescaped -- which turns a symbol
        // containing a slash into extra path segments instead of one opaque
        // value. `Instrument.validSymbolCharacters` matches the actual
        // character range every real ticker uses, so nothing legitimate is
        // affected, and everything else -- "/", "?", "#", whitespace --
        // gets percent-encoded and stays inside this one path segment.
        guard let encodedSymbol = symbol.addingPercentEncoding(withAllowedCharacters: Instrument.validSymbolCharacters),
              let url = URL(string: "https://query1.finance.yahoo.com/v8/finance/chart/\(encodedSymbol)?range=\(range)&interval=1d")
        else {
            throw FetchError.decoding
        }

        var request = URLRequest(url: url, timeoutInterval: requestTimeout)
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw FetchError.network
        }

        guard let http = response as? HTTPURLResponse else {
            throw FetchError.network
        }

        switch http.statusCode {
        case 200:
            break
        case 404:
            throw FetchError.notFound
        case 429:
            throw FetchError.rateLimited(retryAfter: retryAfterSeconds(from: http))
        case 500...599:
            throw FetchError.server(statusCode: http.statusCode)
        default:
            throw FetchError.network
        }

        do {
            let decoded = try JSONDecoder().decode(YahooChartResponse.self, from: data)
            return try decoded.closePoints()
        } catch is YahooChartResponse.ConversionError {
            throw FetchError.notFound
        } catch {
            throw FetchError.decoding
        }
    }

    private func retryAfterSeconds(from response: HTTPURLResponse) -> TimeInterval? {
        guard let header = response.value(forHTTPHeaderField: "Retry-After") else { return nil }
        return TimeInterval(header)
    }
}
