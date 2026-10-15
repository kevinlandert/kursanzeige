import Foundation

/// Reasons a single-symbol fetch can fail, distinguishing errors worth
/// retrying (rate limits, server hiccups, transient network issues) from
/// ones that won't improve on retry (symbol doesn't exist, response
/// couldn't be parsed).
enum FetchError: Error, Equatable {
    case notFound
    case rateLimited(retryAfter: TimeInterval?)
    case server(statusCode: Int)
    case network
    case decoding

    var isRetryable: Bool {
        switch self {
        case .notFound, .decoding: return false
        case .rateLimited, .server, .network: return true
        }
    }
}
