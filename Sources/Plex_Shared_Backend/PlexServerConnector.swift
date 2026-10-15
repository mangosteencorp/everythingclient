import Foundation

/// Resolves advertised addresses inside the library so callers only select a server.
public protocol PlexServerConnecting: Sendable {
    /// Finds a working connection to a server and loads its library sections.
    /// - Parameter allowHTTP: Whether unencrypted connections may be tried after HTTPS ones.
    /// - Throws: `PlexAPIError.noReachableServer` when no connection answers as the expected server.
    func connect(
        to server: PlexServerResource, identity: PlexClientIdentity, allowHTTP: Bool
    ) async throws -> PlexServerConnectionResult
}

/// A verified connection and the sections it returned.
public struct PlexServerConnectionResult: Sendable {
    /// The configuration for the connection that answered first.
    public let configuration: PlexServerConfiguration
    /// The server's library sections.
    public let libraries: [PlexLibrary]

    /// Creates a result, for example in a test double.
    public init(configuration: PlexServerConfiguration, libraries: [PlexLibrary]) {
        self.configuration = configuration
        self.libraries = libraries
    }
}

/// Races a bounded number of advertised connections and keeps the first verified, usable server.
/// HTTPS is preferred; plaintext connections require the caller's explicit opt-in.
public struct PlexServerConnector: PlexServerConnecting {
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
        let configurations = candidates(server: server, identity: identity, allowHTTP: allowHTTP)
        guard !configurations.isEmpty else { throw PlexAPIError.invalidConfiguration }
        return try await withThrowingTaskGroup(of: PlexServerConnectionResult?.self) { group in
            var nextIndex = 0
            for configuration in configurations.prefix(maxConcurrentProbes) {
                group.addTask { try await probe(configuration, serverIdentifier: server.clientIdentifier) }
                nextIndex += 1
            }
            while let result = try await group.next() {
                try Task.checkCancellation()
                if let result {
                    group.cancelAll()
                    return result
                }
                if nextIndex < configurations.count {
                    let configuration = configurations[nextIndex]
                    group.addTask { try await probe(configuration, serverIdentifier: server.clientIdentifier) }
                    nextIndex += 1
                }
            }
            try Task.checkCancellation()
            throw PlexAPIError.noReachableServer
        }
    }

    private func probe(
        _ configuration: PlexServerConfiguration, serverIdentifier: String
    ) async throws -> PlexServerConnectionResult? {
        do {
            let executor = PlexRequestExecutor(transport: transport)
            var identityRequest = try configuration.request(path: "/identity")
            identityRequest.timeoutInterval = requestTimeout
            let identity = try await executor.decode(ServerIdentity.self, request: identityRequest)
            guard identity.mediaContainer.machineIdentifier == serverIdentifier else { return nil }
            var librariesRequest = try PlexEndpoint.libraries.makeRequest(configuration: configuration)
            librariesRequest.timeoutInterval = requestTimeout
            let response = try await executor.decode(PlexResponse.self, request: librariesRequest)
            return PlexServerConnectionResult(configuration: configuration, libraries: response.mediaContainer.libraries)
        } catch {
            try Task.checkCancellation()
            // A failed address should not disclose credentials, URLs or raw transport failures to callers.
            return nil
        }
    }

    private func candidates(
        server: PlexServerResource, identity: PlexClientIdentity, allowHTTP: Bool
    ) -> [PlexServerConfiguration] {
        var seen: Set<String> = []
        var result: [PlexServerConfiguration] = []
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
                let group = connection.relay == true ? 2 : (connection.local == true ? 0 : 1)
                groups[group].append((configuration, connection.ipv6 == true || host.contains(":")))
            }
            // Give local, remote and relay routes a place in the first batch. A long list of
            // unreachable local IPv6 addresses must not keep a working remote route waiting.
            groups = groups.map { $0.filter { !$0.ipv6 } + $0.filter(\.ipv6) }
            let count = groups.map(\.count).max() ?? 0
            for index in 0..<count {
                for group in groups where group.indices.contains(index) { result.append(group[index].configuration) }
            }
        }
        return result
    }
}

private struct ServerIdentity: Decodable, Sendable {
    let mediaContainer: Container
    enum CodingKeys: String, CodingKey { case mediaContainer = "MediaContainer" }
    struct Container: Decodable, Sendable { let machineIdentifier: String }
}
