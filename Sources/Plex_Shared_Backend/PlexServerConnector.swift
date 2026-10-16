import Foundation

/// Resolves advertised addresses inside the library so callers only select a server.
public protocol PlexServerConnecting: Sendable {
    /// Finds a working connection to a server and loads its library sections.
    /// - Parameter allowHTTP: Whether unencrypted connections may be tried after HTTPS ones.
    /// - Throws: `PlexAPIError.noReachableServer` when no connection answers as the expected server.
    func connect(
        to server: PlexServerResource, identity: PlexClientIdentity, allowHTTP: Bool
    ) async throws -> PlexServerConnectionResult

    /// Connects to several servers at once and returns the best one that offers `content`.
    /// The protocol extension implements it on top of `connect(to:identity:allowHTTP:)`.
    /// - Parameter gracePeriod: How long slower servers may still answer after the first usable one.
    /// - Throws: `PlexAPIError.noServerWithContent` when servers answered but none offers `content`,
    ///   otherwise `PlexAPIError.noReachableServer`.
    func connectBest(
        among servers: [PlexServerResource], identity: PlexClientIdentity, content: PlexServerContent, allowHTTP: Bool,
        gracePeriod: Duration
    ) async throws -> PlexBestServerConnection
}

/// A verified connection and the sections it returned.
public struct PlexServerConnectionResult: Sendable {
    /// The configuration for the connection that answered first.
    public let configuration: PlexServerConfiguration
    /// The server's library sections.
    public let libraries: [PlexLibrary]
    /// How the connection that answered reaches the server.
    public let route: PlexServerRoute

    /// Creates a result, for example in a test double.
    public init(configuration: PlexServerConfiguration, libraries: [PlexLibrary], route: PlexServerRoute = .remote) {
        self.configuration = configuration
        self.libraries = libraries
        self.route = route
    }
}

/// How a connection reaches its server, closest first: `local < remote < relay`.
public enum PlexServerRoute: Int, CaseIterable, Comparable, Sendable {
    /// The server's local network.
    case local
    /// A direct internet address.
    case remote
    /// Plex's bandwidth-limited relay.
    case relay

    /// Classifies an advertised address; one without `local` or `relay` flags is remote.
    init(_ connection: PlexServerConnection) {
        self = connection.relay == true ? .relay : (connection.local == true ? .local : .remote)
    }

    /// Whether `lhs` is the closer route.
    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

/// The library types a server must offer for `connectBest` to choose it.
public struct PlexServerContent: OptionSet, Sendable {
    /// The option bits.
    public let rawValue: Int
    /// Creates content from option bits.
    public init(rawValue: Int) { self.rawValue = rawValue }

    /// A `movie` library section.
    public static let movies = Self(rawValue: 1 << 0)
    /// A `show` library section.
    public static let shows = Self(rawValue: 1 << 1)

    /// Whether `libraries` include one of these types; empty content accepts any server.
    func isOffered(by libraries: [PlexLibrary]) -> Bool {
        isEmpty || libraries.contains { (contains(.movies) && $0.type == "movie") || (contains(.shows) && $0.type == "show") }
    }
}

/// The server `connectBest` chose, with the route and reply time that ranked it first.
public struct PlexBestServerConnection: Sendable {
    /// The chosen server.
    public let server: PlexServerResource
    /// Its verified connection and library sections.
    public let connection: PlexServerConnectionResult
    /// How long `connect(to:identity:allowHTTP:)` took for this server, measured with `ContinuousClock`.
    public let latency: Duration
    /// How the chosen connection reaches the server.
    public var route: PlexServerRoute { connection.route }

    /// Creates a result, for example in a test double.
    public init(server: PlexServerResource, connection: PlexServerConnectionResult, latency: Duration) {
        self.server = server
        self.connection = connection
        self.latency = latency
    }

    /// Orders answers best first: the closest route, then the fastest reply, then owned servers, then the given order.
    static func ranked(_ answers: [Self]) -> [Self] {
        let key = { (answer: (offset: Int, element: Self)) in
            (answer.element.route, answer.element.latency, answer.element.server.owned == true ? 0 : 1, answer.offset)
        }
        return answers.enumerated().sorted { key($0) < key($1) }.map(\.element)
    }
}

extension PlexServerConnecting {
    /// Picks a server with movie or show libraries, giving slower servers 1.5 seconds after the first usable answer.
    public func connectBest(
        among servers: [PlexServerResource], identity: PlexClientIdentity,
        content: PlexServerContent = [.movies, .shows], allowHTTP: Bool = false
    ) async throws -> PlexBestServerConnection {
        try await connectBest(among: servers, identity: identity, content: content, allowHTTP: allowHTTP, gracePeriod: .seconds(1.5))
    }

    /// Connects up to four servers at a time and skips each one that fails: offline, answering as another server,
    /// or rejecting an expired token. Once a server offering `content` answers, the rest get `gracePeriod`
    /// (clamped to 0–10 seconds) before they are cancelled; the answers are then ranked by route, reply time,
    /// ownership and discovery order.
    public func connectBest(
        among servers: [PlexServerResource], identity: PlexClientIdentity, content: PlexServerContent, allowHTTP: Bool,
        gracePeriod: Duration
    ) async throws -> PlexBestServerConnection {
        try Task.checkCancellation()
        let servers = servers.filter(\.isServer)
        let gracePeriod = min(max(gracePeriod, .zero), .seconds(10))
        return try await withThrowingTaskGroup(of: BestServerProbe.self) { group in
            var answers = [PlexBestServerConnection?](repeating: nil, count: servers.count)
            var nextIndex = 0, finished = 0, gracePeriodStarted = false
            for (index, server) in servers.enumerated().prefix(4) {
                group.addTask { await self.timedConnect(to: server, index: index, identity: identity, allowHTTP: allowHTTP) }
                nextIndex += 1
            }
            while finished < servers.count, let outcome = try await group.next() {
                try Task.checkCancellation()
                guard case let .finished(index, answer) = outcome else { break }
                finished += 1
                answers[index] = answer
                if !gracePeriodStarted, let answer, content.isOffered(by: answer.connection.libraries) {
                    gracePeriodStarted = true
                    group.addTask { try? await Task.sleep(for: gracePeriod); return .gracePeriodEnded }
                }
                if nextIndex < servers.count {
                    let (index, server) = (nextIndex, servers[nextIndex])
                    group.addTask { await self.timedConnect(to: server, index: index, identity: identity, allowHTTP: allowHTTP) }
                    nextIndex += 1
                }
            }
            group.cancelAll()
            try Task.checkCancellation()
            let reachable = answers.compactMap { $0 }
            guard let best = PlexBestServerConnection.ranked(reachable.filter { content.isOffered(by: $0.connection.libraries) }).first
            else { throw reachable.isEmpty ? PlexAPIError.noReachableServer : PlexAPIError.noServerWithContent }
            return best
        }
    }

    private func timedConnect(
        to server: PlexServerResource, index: Int, identity: PlexClientIdentity, allowHTTP: Bool
    ) async -> BestServerProbe {
        let start = ContinuousClock.now
        guard let result = try? await connect(to: server, identity: identity, allowHTTP: allowHTTP) else { return .finished(index, nil) }
        return .finished(index, PlexBestServerConnection(server: server, connection: result, latency: start.duration(to: .now)))
    }
}

/// Races a bounded number of advertised connections and keeps the first verified, usable server.
/// HTTPS is preferred; plaintext connections require the caller's explicit opt-in.
public struct PlexServerConnector: PlexServerConnecting {
    private typealias Candidate = (configuration: PlexServerConfiguration, route: PlexServerRoute)
    private let transport: any PlexHTTPTransport
    private let requestTimeout: TimeInterval
    private let maxConcurrentProbes: Int

    /// Creates a connector.
    /// - Parameters:
    ///   - transport: Performs the probes.
    ///   - requestTimeout: Per-probe timeout, clamped to 0.25–15 seconds.
    ///   - maxConcurrentProbes: Connections tried at once, clamped to 1–8.
    public init(
        transport: any PlexHTTPTransport = PlexURLSessionTransport(),
        requestTimeout: TimeInterval = 5,
        maxConcurrentProbes: Int = 4
    ) {
        self.transport = transport
        self.requestTimeout = requestTimeout.isFinite ? min(max(requestTimeout, 0.25), 15) : 5
        self.maxConcurrentProbes = min(max(maxConcurrentProbes, 1), 8)
    }

    /// Probes local, remote and relay connections in an interleaved order, HTTPS first, and returns the first one
    /// whose `/identity` matches the server and whose `/library/sections` loads.
    public func connect(
        to server: PlexServerResource, identity: PlexClientIdentity, allowHTTP: Bool = false
    ) async throws -> PlexServerConnectionResult {
        try Task.checkCancellation()
        let candidates = self.candidates(server: server, identity: identity, allowHTTP: allowHTTP)
        guard !candidates.isEmpty else { throw PlexAPIError.invalidConfiguration }
        return try await withThrowingTaskGroup(of: PlexServerConnectionResult?.self) { group in
            var nextIndex = 0
            for candidate in candidates.prefix(maxConcurrentProbes) {
                group.addTask { try await probe(candidate, serverIdentifier: server.clientIdentifier) }
                nextIndex += 1
            }
            while let result = try await group.next() {
                try Task.checkCancellation()
                if let result {
                    group.cancelAll()
                    return result
                }
                if nextIndex < candidates.count {
                    let candidate = candidates[nextIndex]
                    group.addTask { try await probe(candidate, serverIdentifier: server.clientIdentifier) }
                    nextIndex += 1
                }
            }
            try Task.checkCancellation()
            throw PlexAPIError.noReachableServer
        }
    }

    private func probe(_ candidate: Candidate, serverIdentifier: String) async throws -> PlexServerConnectionResult? {
        do {
            let executor = PlexRequestExecutor(transport: transport)
            var identityRequest = try candidate.configuration.request(path: "/identity")
            identityRequest.timeoutInterval = requestTimeout
            let identity = try await executor.decode(ServerIdentity.self, request: identityRequest)
            guard identity.mediaContainer.machineIdentifier == serverIdentifier else { return nil }
            var librariesRequest = try PlexEndpoint.libraries.makeRequest(configuration: candidate.configuration)
            librariesRequest.timeoutInterval = requestTimeout
            let response = try await executor.decode(PlexResponse.self, request: librariesRequest)
            return PlexServerConnectionResult(
                configuration: candidate.configuration, libraries: response.mediaContainer.libraries, route: candidate.route
            )
        } catch {
            try Task.checkCancellation()
            // A failed address should not disclose credentials, URLs or raw transport failures to callers.
            return nil
        }
    }

    private func candidates(server: PlexServerResource, identity: PlexClientIdentity, allowHTTP: Bool) -> [Candidate] {
        var seen: Set<String> = []
        var result: [Candidate] = []
        for scheme in allowHTTP ? ["https", "http"] : ["https"] {
            var groups = Array(repeating: [(configuration: PlexServerConfiguration, ipv6: Bool)](), count: 3)
            for (index, connection) in server.connections.enumerated() {
                guard var components = URLComponents(url: connection.uri, resolvingAgainstBaseURL: false),
                      components.scheme?.lowercased() == scheme,
                      let host = components.host, !host.isEmpty,
                      (1...65_535).contains(components.port ?? (scheme == "https" ? 443 : 80)),
                      host.rangeOfCharacter(from: .whitespacesAndNewlines.union(.controlCharacters)) == nil,
                      let configuration = try? server.configuration(connectionIndex: index, identity: identity)
                else { continue }
                components.scheme = scheme
                components.host = host.lowercased()
                if components.port == (scheme == "https" ? 443 : 80) { components.port = nil }
                while components.percentEncodedPath.hasSuffix("/") { components.percentEncodedPath.removeLast() }
                guard let key = components.string, seen.insert(key).inserted else { continue }
                groups[PlexServerRoute(connection).rawValue].append((configuration, connection.ipv6 == true || host.contains(":")))
            }
            // Give local, remote and relay routes a place in the first batch. A long list of
            // unreachable local IPv6 addresses must not keep a working remote route waiting.
            groups = groups.map { $0.filter { !$0.ipv6 } + $0.filter(\.ipv6) }
            let count = groups.map(\.count).max() ?? 0
            for index in 0..<count {
                for (route, group) in zip(PlexServerRoute.allCases, groups) where group.indices.contains(index) {
                    result.append((group[index].configuration, route))
                }
            }
        }
        return result
    }
}

private enum BestServerProbe: Sendable {
    case finished(Int, PlexBestServerConnection?)
    case gracePeriodEnded
}

private struct ServerIdentity: Decodable, Sendable {
    let mediaContainer: Container
    enum CodingKeys: String, CodingKey { case mediaContainer = "MediaContainer" }
    struct Container: Decodable, Sendable { let machineIdentifier: String }
}
