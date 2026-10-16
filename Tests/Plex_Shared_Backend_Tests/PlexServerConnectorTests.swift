import Foundation
@testable import Plex_Shared_Backend
import Testing

struct PlexServerConnectorTests {
    @Test func skipsUnreachableAddressAndReturnsVerifiedLibraries() async throws {
        let transport = ConnectorTransport(routes: ["working.example": .server()])
        let server = try connectorResource([
            ["uri": "https://unreachable.example", "local": true],
            ["uri": "https://working.example"],
        ])
        let result = try await PlexServerConnector(transport: transport, requestTimeout: 2, maxConcurrentProbes: 1)
            .connect(to: server, identity: testIdentity())
        #expect(result.configuration.baseURL.host == "working.example")
        #expect(result.libraries.map(\.key) == ["1"])
        let requests = await transport.requests
        #expect(requests.map { $0.url?.path } == ["/identity", "/identity", "/library/sections"])
        #expect(requests.allSatisfy { $0.timeoutInterval == 2 })
    }

    @Test func manyLocalIPv6AddressesDoNotDelayRemoteAndLosingProbesAreCancelled() async throws {
        let locals = (0..<30).map { ["uri": "https://local-\($0).example", "local": true, "IPv6": true] as [String: Any] }
        let server = try connectorResource(locals + [["uri": "https://remote.example"]])
        var routes = Dictionary(uniqueKeysWithValues: (0..<30).map { ("local-\($0).example", ConnectorRoute.waiting) })
        routes["remote.example"] = .server(delay: 20_000_000)
        let transport = ConnectorTransport(routes: routes)
        let result = try await PlexServerConnector(transport: transport, maxConcurrentProbes: 2)
            .connect(to: server, identity: testIdentity())
        #expect(result.configuration.baseURL.host == "remote.example")
        #expect(await transport.requests.count == 3)
        #expect(await transport.cancelledRequests == 1)
        #expect(await transport.maximumActiveRequests <= 2)
    }

    @Test func rejectsOtherServerIdentityAndLibraryFailures() async throws {
        let transport = ConnectorTransport(routes: [
            "wrong.example": .server(identifier: "other-server"),
            "forbidden.example": .server(librariesStatus: 403),
            "working.example": .server(),
        ])
        let server = try connectorResource([
            ["uri": "https://wrong.example"],
            ["uri": "https://forbidden.example"],
            ["uri": "https://working.example"],
        ])
        let result = try await PlexServerConnector(transport: transport, maxConcurrentProbes: 1)
            .connect(to: server, identity: testIdentity())
        #expect(result.configuration.baseURL.host == "working.example")
        let requests = await transport.requests
        #expect(!requests.contains { $0.url?.host == "wrong.example" && $0.url?.path == "/library/sections" })
        #expect(requests.allSatisfy { $0.value(forHTTPHeaderField: "X-Plex-Token") == "resource-token" })
        #expect(requests.allSatisfy { $0.url?.query == nil })
    }

    @Test func deduplicatesEquivalentURLsAndSkipsUnsafeAddresses() async throws {
        let transport = ConnectorTransport(routes: ["working.example": .server()])
        let server = try connectorResource([
            ["uri": "https://unreachable.example"],
            ["uri": "https://UNREACHABLE.example:443/"],
            ["uri": "https://unreachable.example/"],
            ["uri": "https://user:password@unsafe.example"],
            ["uri": "https://unsafe.example?X-Plex-Token=token"],
            ["uri": "https://unsafe.example/a/../b"],
            ["uri": "https://working.example"],
        ])
        _ = try await PlexServerConnector(transport: transport, maxConcurrentProbes: 1)
            .connect(to: server, identity: testIdentity())
        let requests = await transport.requests
        #expect(requests.count == 3)
        #expect(requests.allSatisfy { $0.url?.host != "unsafe.example" })
    }

    @Test func plaintextRequiresExplicitOptIn() async throws {
        let transport = ConnectorTransport(routes: ["local.example": .server()])
        let server = try connectorResource([["uri": "http://local.example", "local": true]])
        let connector = PlexServerConnector(transport: transport)
        await #expect(throws: PlexAPIError.invalidConfiguration) {
            try await connector.connect(to: server, identity: testIdentity())
        }
        #expect(await transport.requests.isEmpty)
        let result = try await connector.connect(to: server, identity: testIdentity(), allowHTTP: true)
        #expect(result.configuration.baseURL.scheme == "http")
    }

    @Test func prefersHTTPSBeforeAllowedPlaintext() async throws {
        let transport = ConnectorTransport(routes: ["local.example": .server(), "remote.example": .server()])
        let server = try connectorResource([
            ["uri": "http://local.example", "local": true], ["uri": "https://remote.example"],
        ])
        let result = try await PlexServerConnector(transport: transport, maxConcurrentProbes: 1)
            .connect(to: server, identity: testIdentity(), allowHTTP: true)
        #expect(result.configuration.baseURL.host == "remote.example")
        #expect(await transport.requests.allSatisfy { $0.url?.scheme == "https" })
    }

    @Test func missingResourceTokenFailsWithoutNetwork() async throws {
        let transport = ConnectorTransport(routes: [:])
        let server = try connectorResource([["uri": "https://working.example"]], token: nil)
        await #expect(throws: PlexAPIError.invalidConfiguration) {
            try await PlexServerConnector(transport: transport).connect(to: server, identity: testIdentity())
        }
        #expect(await transport.requests.isEmpty)
    }

    @Test func reportsSafeFailureWhenEveryAddressFails() async throws {
        let transport = ConnectorTransport(routes: ["wrong.example": .server(identifier: "wrong")])
        let server = try connectorResource([["uri": "https://offline.example"], ["uri": "https://wrong.example"]])
        await #expect(throws: PlexAPIError.noReachableServer) {
            try await PlexServerConnector(transport: transport).connect(to: server, identity: testIdentity())
        }
    }

    @Test func cancellationStopsAllActiveProbesAndDoesNotTryRemainingCandidates() async throws {
        let transport = ConnectorTransport(routes: ["one.example": .waiting, "two.example": .waiting])
        let server = try connectorResource([
            ["uri": "https://one.example"], ["uri": "https://two.example"], ["uri": "https://three.example"],
        ])
        let identity = try testIdentity()
        let task = Task {
            try await PlexServerConnector(transport: transport, maxConcurrentProbes: 2)
                .connect(to: server, identity: identity)
        }
        for _ in 0..<10_000 {
            if await transport.requests.count == 2 { break }
            await Task.yield()
        }
        task.cancel()
        await #expect(throws: CancellationError.self) { try await task.value }
        #expect(await transport.requests.count == 2)
        #expect(await transport.cancelledRequests == 2)
    }
}

struct PlexBestServerTests {
    @Test func rankingPrefersCloserRoutesThenFasterRepliesThenOwnedServers() throws {
        func answer(_ id: String, _ route: PlexServerRoute, _ milliseconds: Int, owned: Bool = false) throws -> PlexBestServerConnection {
            let result = try PlexServerConnectionResult(configuration: testConfiguration(), libraries: [], route: route)
            let server = try connectorResource([["uri": "https://\(id).example"]], id: id, owned: owned)
            return PlexBestServerConnection(server: server, connection: result, latency: .milliseconds(milliseconds))
        }
        let ranked = try PlexBestServerConnection.ranked([
            answer("relay", .relay, 5, owned: true), answer("slow-remote", .remote, 300), answer("shared-local", .local, 40),
            answer("fast-remote", .remote, 20), answer("owned-local", .local, 40, owned: true), answer("second-local", .local, 40),
        ])
        #expect(ranked.map(\.server.id) == ["owned-local", "shared-local", "second-local", "fast-remote", "slow-remote", "relay"])
    }

    @Test func skipsDeadExpiredAndContentlessServersAndChoosesTheWorkingMovieServer() async throws {
        let transport = ConnectorTransport(routes: [
            "expired.example": .server(identifier: "expired", librariesStatus: 401),
            "music.example": .server(identifier: "music", sectionType: "artist"),
            "movies.example": .server(identifier: "movies"),
        ])
        let servers = try [
            connectorResource([["uri": "https://dead.example", "local": true]], id: "dead", owned: true),
            connectorResource([["uri": "https://expired.example", "local": true]], id: "expired", owned: true),
            connectorResource([["uri": "https://music.example", "local": true]], id: "music"),
            connectorResource([["uri": "https://movies.example", "relay": true]], id: "movies"),
            connectorResource([["uri": "https://movies.example"]], id: "no-token", token: nil),
        ]
        let best = try await PlexServerConnector(transport: transport).connectBest(among: servers, identity: testIdentity())
        #expect(best.server.id == "movies" && best.route == .relay && best.latency > .zero)
        #expect(best.connection.libraries.map(\.type) == ["movie"] && best.connection.configuration.baseURL.host == "movies.example")
    }

    @Test func reportsWhetherNoServerAnsweredOrNoneOffersTheContent() async throws {
        let transport = ConnectorTransport(routes: ["music.example": .server(identifier: "music", sectionType: "artist")])
        let dead = try connectorResource([["uri": "https://dead.example"]], id: "dead")
        let music = try connectorResource([["uri": "https://music.example"]], id: "music")
        let connector = PlexServerConnector(transport: transport)
        await #expect(throws: PlexAPIError.noReachableServer) { try await connector.connectBest(among: [], identity: testIdentity()) }
        await #expect(throws: PlexAPIError.noReachableServer) { try await connector.connectBest(among: [dead], identity: testIdentity()) }
        await #expect(throws: PlexAPIError.noServerWithContent) {
            try await connector.connectBest(among: [dead, music], identity: testIdentity())
        }
        #expect(try await connector.connectBest(among: [dead, music], identity: testIdentity(), content: []).server.id == "music")
    }

    @Test func gracePeriodCancelsAServerThatNeverAnswers() async throws {
        let transport = ConnectorTransport(routes: ["hanging.example": .waiting, "remote.example": .server(identifier: "remote")])
        let servers = try [
            connectorResource([["uri": "https://hanging.example", "local": true]], id: "hanging", owned: true),
            connectorResource([["uri": "https://remote.example"]], id: "remote"),
        ]
        let best = try await PlexServerConnector(transport: transport).connectBest(
            among: servers, identity: testIdentity(), content: .movies, allowHTTP: false, gracePeriod: .milliseconds(20)
        )
        #expect(best.server.id == "remote" && best.route == .remote)
        #expect(await transport.cancelledRequests == 1)
    }

    @Test func closerServerThatAnswersWithinTheGracePeriodWins() async throws {
        let transport = ConnectorTransport(routes: [
            "relay.example": .server(identifier: "relay"), "local.example": .server(identifier: "local", delay: 30_000_000),
        ])
        let servers = try [
            connectorResource([["uri": "https://relay.example", "relay": true]], id: "relay", owned: true),
            connectorResource([["uri": "https://local.example", "local": true]], id: "local"),
        ]
        let best = try await PlexServerConnector(transport: transport).connectBest(
            among: servers, identity: testIdentity(), content: .movies, allowHTTP: false, gracePeriod: .seconds(5)
        )
        #expect(best.server.id == "local" && best.route == .local)
    }

    @Test func cancellationStopsEveryServerProbe() async throws {
        let transport = ConnectorTransport(routes: ["one.example": .waiting, "two.example": .waiting])
        let servers = try [
            connectorResource([["uri": "https://one.example"]], id: "one"), connectorResource([["uri": "https://two.example"]], id: "two"),
        ]
        let identity = try testIdentity()
        let task = Task { try await PlexServerConnector(transport: transport).connectBest(among: servers, identity: identity) }
        for _ in 0..<10_000 {
            if await transport.requests.count == 2 { break }
            await Task.yield()
        }
        task.cancel()
        await #expect(throws: CancellationError.self) { try await task.value }
        #expect(await transport.cancelledRequests == 2)
    }

    @Test func connectReportsTheRouteThatAnswered() async throws {
        let transport = ConnectorTransport(routes: ["relay.example": .server()])
        let server = try connectorResource([
            ["uri": "https://local.example", "local": true], ["uri": "https://relay.example", "relay": true],
        ])
        let result = try await PlexServerConnector(transport: transport).connect(to: server, identity: testIdentity())
        #expect(result.configuration.baseURL.host == "relay.example" && result.route == .relay)
        #expect(PlexServerConnectionResult(configuration: result.configuration, libraries: []).route == .remote)
    }
}

private func connectorResource(
    _ connections: [[String: Any]], id: String = "expected-server", owned: Bool? = nil, token: String? = "resource-token"
) throws -> PlexServerResource {
    var json: [String: Any] = ["clientIdentifier": id, "name": "Test Server", "provides": "server", "connections": connections]
    if let owned { json["owned"] = owned }
    if let token { json["accessToken"] = token }
    return try JSONDecoder().decode(PlexServerResource.self, from: JSONSerialization.data(withJSONObject: json))
}

private enum ConnectorRoute: Sendable {
    case server(identifier: String = "expected-server", librariesStatus: Int = 200, delay: UInt64 = 0, sectionType: String = "movie")
    case waiting
}

private actor ConnectorTransport: PlexHTTPTransport {
    let routes: [String: ConnectorRoute]
    private(set) var requests: [URLRequest] = []
    private(set) var cancelledRequests = 0
    private(set) var maximumActiveRequests = 0
    private var activeRequests = 0

    init(routes: [String: ConnectorRoute]) { self.routes = routes }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request)
        activeRequests += 1
        maximumActiveRequests = max(maximumActiveRequests, activeRequests)
        defer { activeRequests -= 1 }
        let url = try #require(request.url)
        guard let route = routes[url.host ?? ""] else { throw URLError(.cannotConnectToHost) }
        do {
            switch route {
            case let .server(identifier, librariesStatus, delay, sectionType):
                if delay > 0 { try await Task.sleep(nanoseconds: delay) }
                let identity = url.path == "/identity"
                let json = identity ? "{\"MediaContainer\":{\"machineIdentifier\":\"\(identifier)\"}}"
                    : #"{"MediaContainer":{"Directory":[{"key":"1","title":"Movies","type":"\#(sectionType)"}]}}"#
                let response = try #require(HTTPURLResponse(
                    url: url, statusCode: identity ? 200 : librariesStatus, httpVersion: "HTTP/1.1", headerFields: nil
                ))
                return (Data(json.utf8), response)
            case .waiting:
                try await Task.sleep(nanoseconds: 60_000_000_000)
                throw URLError(.timedOut)
            }
        } catch {
            if Task.isCancelled { cancelledRequests += 1 }
            throw error
        }
    }
}
