import CryptoKit
import Foundation
import Synchronization

/// Stores raw JSON responses by key. Implement it to use another database.
public protocol PlexResponseCaching: Sendable {
    /// The cached body for `key`, if any.
    func response(for key: String) async -> Data?
    /// Saves a body under `key`, replacing any previous one.
    func store(_ data: Data, for key: String) async
    /// Deletes every cached response.
    func removeAll() async
}

/// One file per response under `directory`, named by a hash of the key so no IDs or paths reach the file system.
/// Only bodies are stored, never request headers, so server tokens stay out of the cache.
public actor PlexDiskResponseCache: PlexResponseCaching {
    /// Where response files are stored.
    public let directory: URL

    /// Creates a cache in `directory`; the directory is created on first write.
    public init(directory: URL) {
        self.directory = directory
    }

    /// Reads the response file for `key`.
    public func response(for key: String) -> Data? { try? Data(contentsOf: file(for: key)) }

    /// Writes the response file atomically with file protection.
    public func store(_ data: Data, for key: String) {
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? data.write(to: file(for: key), options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }

    /// Deletes the cache directory.
    public func removeAll() { try? FileManager.default.removeItem(at: directory) }

    private func file(for key: String) -> URL {
        directory.appending(path: SHA256.hash(data: Data(key.utf8)).map { String(format: "%02x", $0) }.joined() + ".cache")
    }
}

/// Plezy's offline model as a transport decorator: JSON GETs go to the network first and are cached;
/// when the network fails, or `isOffline` is on, the cached response is returned instead.
/// Artwork (`Accept: image/*`) is served cache-first, since Plex image paths change when the image does.
/// Mutations and other binary resources are never cached; offline they fail with `PlexAPIError.offline`.
public final class PlexCachingTransport: PlexHTTPTransport {
    private let upstream: any PlexHTTPTransport
    private let cache: any PlexResponseCaching
    private let scope: String
    private let offline = Mutex(false)

    /// `scope` separates servers (use the machine identifier) so different servers never share entries.
    public init(upstream: any PlexHTTPTransport = PlexURLSessionTransport(), cache: any PlexResponseCaching, scope: String) {
        self.upstream = upstream
        self.cache = cache
        self.scope = scope
    }

    /// Cache-only mode, for when the app knows it has no connection.
    public var isOffline: Bool {
        get { offline.withLock { $0 } }
        set { offline.withLock { $0 = newValue } }
    }

    /// Serves JSON GETs network-first with cache fallback, artwork cache-first, and both cache-only when offline.
    /// - Throws: `PlexAPIError.offline` when offline (or the network failed) and nothing is cached.
    public func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        guard let key = cacheKey(for: request) else {
            if isOffline { throw PlexAPIError.offline }
            return try await upstream.data(for: request)
        }
        if isOffline { return try await cached(key, request) }
        if key.hasPrefix("image|"), let hit = try? await cached(key, request) { return hit }
        do {
            let (data, response) = try await upstream.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            if (200..<300).contains(status) {
                await cache.store(data, for: key)
            } else if status >= 500, let fallback = try? await cached(key, request) {
                return fallback
            }
            return (data, response)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            guard let fallback = try? await cached(key, request) else { throw error }
            return fallback
        }
    }

    /// Only JSON and image GETs are cached. Host, port and credentials are excluded so any connection to the
    /// server can reuse an entry.
    private func cacheKey(for request: URLRequest) -> String? {
        let accept = request.value(forHTTPHeaderField: "Accept") ?? ""
        guard request.httpMethod ?? "GET" == "GET", accept == "application/json" || accept.hasPrefix("image/"),
              let url = request.url, let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else { return nil }
        let query = (components.queryItems ?? []).sorted { ($0.name, $0.value ?? "") < ($1.name, $1.value ?? "") }
            .map { "\($0.name)=\($0.value ?? "")" }.joined(separator: "&")
        return (accept.hasPrefix("image/") ? "image|" : "json|") + scope + "|" + components.percentEncodedPath + "?" + query
    }

    private func cached(_ key: String, _ request: URLRequest) async throws -> (Data, URLResponse) {
        let type = key.hasPrefix("image|") ? "application/octet-stream" : "application/json"
        guard let data = await cache.response(for: key), let url = request.url,
              let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": type])
        else { throw PlexAPIError.offline }
        return (data, response)
    }
}
