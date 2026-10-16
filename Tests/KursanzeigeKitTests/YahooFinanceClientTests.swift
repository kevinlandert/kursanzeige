import Testing
import Foundation
@testable import KursanzeigeKit

/// Intercepts URLSession requests so the client's status-code mapping can
/// be tested without touching the real network. Responses are scripted
/// per test via `MockURLProtocol.stub`.
final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var stub: ((URLRequest) -> (Int, Data, [String: String])) = { _ in (200, Data(), [:]) }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let (status, data, headers) = Self.stub(request)
        let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: "HTTP/1.1", headerFields: headers)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

private func mockSession() -> URLSession {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [MockURLProtocol.self]
    return URLSession(configuration: config)
}

// `MockURLProtocol.stub` is shared process-wide mutable state (URLProtocol
// gives no per-request hook to inject a fake response); .serialized keeps
// these tests from racing each other's stubs under Swift Testing's default
// parallel execution.
@Suite(.serialized)
struct YahooFinanceClientTests {

    @Test func mapsSuccessfulResponseToClosePoints() async throws {
        let json = try Data(contentsOf: try #require(Bundle.module.url(forResource: "NESN.SW", withExtension: "json", subdirectory: "Fixtures")))
        MockURLProtocol.stub = { _ in (200, json, [:]) }
        let client = YahooFinanceClient(session: mockSession())

        let fetched = try await client.fetchCloses(for: "NESN.SW")

        #expect(!fetched.closes.isEmpty)
        #expect(fetched.unit == .currency("CHF"))
    }

    @Test func mapsHttp404ToNotFound() async throws {
        MockURLProtocol.stub = { _ in (404, Data(), [:]) }
        let client = YahooFinanceClient(session: mockSession())

        await #expect(throws: FetchError.notFound) {
            _ = try await client.fetchCloses(for: "NOPE")
        }
    }

    @Test func mapsHttp429ToRateLimitedWithRetryAfterHeader() async throws {
        MockURLProtocol.stub = { _ in (429, Data(), ["Retry-After": "30"]) }
        let client = YahooFinanceClient(session: mockSession())

        await #expect(throws: FetchError.rateLimited(retryAfter: 30)) {
            _ = try await client.fetchCloses(for: "ANY")
        }
    }

    @Test func mapsHttp500ToServerError() async throws {
        MockURLProtocol.stub = { _ in (500, Data(), [:]) }
        let client = YahooFinanceClient(session: mockSession())

        await #expect(throws: FetchError.server(statusCode: 500)) {
            _ = try await client.fetchCloses(for: "ANY")
        }
    }

    @Test func mapsUnparsableBodyOnSuccessToDecodingError() async throws {
        MockURLProtocol.stub = { _ in (200, Data("not json".utf8), [:]) }
        let client = YahooFinanceClient(session: mockSession())

        await #expect(throws: FetchError.decoding) {
            _ = try await client.fetchCloses(for: "ANY")
        }
    }

    @Test func asksForFiveYearsOfDailyClosesByDefault() async throws {
        let log = RequestLog()
        MockURLProtocol.stub = { request in
            log.record(request)
            return (404, Data(), [:])
        }
        let client = YahooFinanceClient(session: mockSession())

        _ = try? await client.fetchCloses(for: "NESN.SW")

        let query = try #require(log.last?.url?.query)
        #expect(query.contains("range=5y"))
        #expect(query.contains("interval=1d"))
    }

    @Test func appliesTheGivenRequestTimeout() async throws {
        let log = RequestLog()
        MockURLProtocol.stub = { request in
            log.record(request)
            return (404, Data(), [:])
        }
        let client = YahooFinanceClient(session: mockSession(), requestTimeout: 10)

        _ = try? await client.fetchCloses(for: "NESN.SW")

        #expect(log.last?.timeoutInterval == 10)
    }

    @Test func usesAShorterTimeoutThanTheSystemDefault() async throws {
        let log = RequestLog()
        MockURLProtocol.stub = { request in
            log.record(request)
            return (404, Data(), [:])
        }
        let client = YahooFinanceClient(session: mockSession())

        _ = try? await client.fetchCloses(for: "NESN.SW")

        #expect(try #require(log.last?.timeoutInterval) < 60)
    }
}

/// Keeps the requests that reach `MockURLProtocol`, so a test can check
/// what the client asked for.
private final class RequestLog: @unchecked Sendable {
    private var requests: [URLRequest] = []
    private let lock = NSLock()

    func record(_ request: URLRequest) {
        lock.withLock { requests.append(request) }
    }

    var last: URLRequest? {
        lock.withLock { requests.last }
    }
}
