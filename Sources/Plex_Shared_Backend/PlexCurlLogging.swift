import Foundation
import os
import Synchronization

extension URLRequest {
    /// Header and query names whose values are credentials.
    static let plexSensitiveNames: Set<String> = ["x-plex-token", "authorization", "cookie", "pin", "token"]

    /// The request as a copy-pasteable `curl` command.
    /// - Parameter redactingCredentials: Replaces `X-Plex-Token`, `Authorization`, cookies and profile PINs with
    ///   `[redacted]`. Pass `false` only on a trusted machine: the output then contains live credentials.
    public func curlCommand(redactingCredentials: Bool = true) -> String {
        func quoted(_ value: String) -> String { "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'" }
        func hides(_ name: String) -> Bool { redactingCredentials && Self.plexSensitiveNames.contains(name.lowercased()) }
        var components = url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }
        let items = components?.percentEncodedQueryItems?.map {
            URLQueryItem(name: $0.name, value: hides($0.name) ? "%5Bredacted%5D" : $0.value)
        }
        components?.percentEncodedQueryItems = items
        var parts = ["curl"]
        if let method = httpMethod, method != "GET" { parts.append("-X \(method)") }
        parts.append(quoted(components?.string ?? url?.absoluteString ?? ""))
        for (name, value) in (allHTTPHeaderFields ?? [:]).sorted(by: { $0.key < $1.key }) {
            parts.append("-H " + quoted("\(name): \(hides(name) ? "[redacted]" : value)"))
        }
        if let body = httpBody, !body.isEmpty {
            parts.append(String(bytes: body, encoding: .utf8).map { "--data-binary " + quoted($0) } ?? "--data-binary '<\(body.count) bytes>'")
        }
        return parts.joined(separator: " \\\n  ")
    }
}

/// The switch for seeing every Plex network call as a `curl` command.
/// Share one logger between `PlexCurlLoggingTransport`, `PlexEventSource` and any app-owned requests
/// (downloads, players) so a single toggle covers everything sent to plex.tv and the server.
public final class PlexCurlLogger: Sendable {
    private let state: Mutex<(enabled: Bool, redacting: Bool)>
    private let sink: @Sendable (String) -> Void

    /// Writes to the unified log (subsystem `Plex_Shared_Backend`, category `curl`), visible in Xcode's console.
    public static let systemSink: @Sendable (String) -> Void = { line in
        Logger(subsystem: "Plex_Shared_Backend", category: "curl").debug("\(line, privacy: .public)")
    }

    /// Creates a logger.
    /// - Parameters:
    ///   - isEnabled: Whether requests are logged; it can be toggled later.
    ///   - redactsCredentials: Whether tokens and PINs are replaced with `[redacted]`.
    ///   - sink: Receives each command; defaults to the unified log.
    public init(isEnabled: Bool = false, redactsCredentials: Bool = true, sink: @escaping @Sendable (String) -> Void = PlexCurlLogger.systemSink) {
        state = Mutex((isEnabled, redactsCredentials))
        self.sink = sink
    }

    /// Whether requests are currently logged.
    public var isEnabled: Bool {
        get { state.withLock { $0.enabled } }
        set { state.withLock { $0.enabled = newValue } }
    }

    /// Whether credentials are redacted. Keep this on unless you need to replay a request yourself.
    public var redactsCredentials: Bool {
        get { state.withLock { $0.redacting } }
        set { state.withLock { $0.redacting = newValue } }
    }

    /// Logs `request` as a `curl` command when enabled.
    public func log(_ request: URLRequest) {
        let (enabled, redacting) = state.withLock { ($0.enabled, $0.redacting) }
        guard enabled else { return }
        sink(request.curlCommand(redactingCredentials: redacting))
    }
}

/// Logs each request through `logger`, then forwards it unchanged. Wrap the transport given to
/// `PlexAccountService`, `PlexServerConnector` and `PlexAPIService` (inside any `PlexCachingTransport`
/// to log only real network calls).
public struct PlexCurlLoggingTransport: PlexHTTPTransport {
    private let upstream: any PlexHTTPTransport
    /// The logger that decides whether and how requests are logged.
    public let logger: PlexCurlLogger

    /// Creates a logging transport.
    public init(upstream: any PlexHTTPTransport = PlexURLSessionTransport(), logger: PlexCurlLogger) {
        self.upstream = upstream
        self.logger = logger
    }

    /// Logs the request, then sends it through `upstream`.
    public func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        logger.log(request)
        return try await upstream.data(for: request)
    }
}
