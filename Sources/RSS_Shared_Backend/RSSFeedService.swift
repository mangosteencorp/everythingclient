import Foundation

/// Loads RSS feeds. Features depend on this, so tests and previews can return a feed without the network.
public protocol RSSFeedProviding: Sendable {
    /// The parsed feed at `url`.
    /// - Throws: `RSSFeedError`, `RSSParserError`, or the transport's own error.
    func feed(at url: URL) async throws -> RSSFeed
}

/// HTTP failures; bodies are dropped.
public enum RSSFeedError: Error, Equatable, Sendable {
    /// The transport returned something other than an HTTP response.
    case nonHTTPResponse
    /// The server answered with a non-2xx status code.
    case httpStatus(Int)
}

/// Fetches and parses feeds, keeping each in memory for `timeToLive`: the IGN feed is close to 1 MB and every
/// movie page asks for it. Concurrent requests for one URL share a download, and failures are not kept.
public actor RSSFeedService: RSSFeedProviding {
    /// One app-wide instance, so every screen shares the cache.
    public static let shared = RSSFeedService()

    private let transport: any RSSHTTPTransport
    private let timeToLive: Duration
    private var cache: [URL: (task: Task<RSSFeed, any Error>, createdAt: ContinuousClock.Instant)] = [:]

    /// - Parameters:
    ///   - transport: Performs the HTTP calls; a stub in tests.
    ///   - timeToLive: How long a fetched feed is reused before the next request downloads it again.
    public init(transport: any RSSHTTPTransport = RSSURLSessionTransport(), timeToLive: Duration = .seconds(30 * 60)) {
        self.transport = transport
        self.timeToLive = timeToLive
    }

    /// The cached feed while it is fresh, otherwise a new download.
    /// - Throws: `RSSFeedError` for non-HTTP or non-2xx responses, `RSSParserError` for a body that isn't RSS.
    public func feed(at url: URL) async throws -> RSSFeed {
        if let entry = cache[url], entry.createdAt.duration(to: .now) < timeToLive {
            return try await entry.task.value
        }
        let task = Task { [transport] in try await Self.fetch(url, transport: transport) }
        cache[url] = (task, .now)
        do {
            return try await task.value
        } catch {
            if cache[url]?.task == task { cache[url] = nil }
            throw error
        }
    }

    private static func fetch(_ url: URL, transport: any RSSHTTPTransport) async throws -> RSSFeed {
        let (data, response) = try await transport.data(for: URLRequest(url: url))
        guard let status = (response as? HTTPURLResponse)?.statusCode else { throw RSSFeedError.nonHTTPResponse }
        guard (200..<300).contains(status) else { throw RSSFeedError.httpStatus(status) }
        return try RSSParser().parse(data)
    }
}
