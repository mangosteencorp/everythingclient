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

private func connectorResource(
    _ connections: [[String: Any]], token: String? = "resource-token"
) throws -> PlexServerResource {
    var json: [String: Any] = [
        "clientIdentifier": "expected-server", "name": "Test Server", "provides": "server", "connections": connections,
    ]
    if let token { json["accessToken"] = token }
    return try JSONDecoder().decode(PlexServerResource.self, from: JSONSerialization.data(withJSONObject: json))
}

private enum ConnectorRoute: Sendable {
    case server(identifier: String = "expected-server", librariesStatus: Int = 200, delay: UInt64 = 0)
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
            case let .server(identifier, librariesStatus, delay):
                if delay > 0 { try await Task.sleep(nanoseconds: delay) }
                let identity = url.path == "/identity"
                let json = identity ? "{\"MediaContainer\":{\"machineIdentifier\":\"\(identifier)\"}}"
                    : #"{"MediaContainer":{"Directory":[{"key":"1","title":"Movies","type":"movie"}]}}"#
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
