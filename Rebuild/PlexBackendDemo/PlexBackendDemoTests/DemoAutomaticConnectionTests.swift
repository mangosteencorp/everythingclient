import Foundation
import Plex_Shared_Backend
@testable import PlexBackendDemo
import Testing

private func automaticTestServers() throws -> [PlexServerResource] {
    try JSONDecoder().decode([PlexServerResource].self, from: Data(#"""
    [
      {"clientIdentifier":"shared","name":"Shared server","provides":"server","owned":false,
       "accessToken":"shared-token","connections":[{"uri":"https://shared.invalid"}]},
      {"clientIdentifier":"owned","name":"My server","provides":"server","owned":true,
       "accessToken":"owned-token","connections":[{"uri":"https://offline.invalid","local":true},{"uri":"https://owned.invalid"}]}
    ]
    """#.utf8))
}

private struct AutomaticAccount: PlexAccountServing, PlexAccountProfileServing {
    func createPIN() async throws -> PlexPIN { try pinValue(authorized: false) }
    func pin(id: String) async throws -> PlexPIN { try pinValue(authorized: true) }
    func authorizationURL(code: String) throws -> URL { try #require(URL(string: "https://app.plex.tv/auth")) }
    func servers(accountToken: String) async throws -> [PlexServerResource] {
        #expect(accountToken == "account-token")
        return try automaticTestServers()
    }

    func user(accountToken: String) async throws -> PlexAccountUser {
        try JSONDecoder().decode(PlexAccountUser.self, from: Data(#"{"id":1,"title":"Owner"}"#.utf8))
    }

    func homeUsers(accountToken: String) async throws -> [PlexAccountUser] { [] }
    func switchUser(uuid: String, pin: String?, accountToken: String) async throws -> PlexAccountSession {
        throw PlexAPIError.invalidConfiguration
    }

    private func pinValue(authorized: Bool) throws -> PlexPIN {
        let json = authorized ? #"{"id":"1","code":"TEST","authToken":"account-token"}"# : #"{"id":"1","code":"TEST"}"#
        return try JSONDecoder().decode(PlexPIN.self, from: Data(json.utf8))
    }
}

private actor AutomaticConnectionTransport: PlexHTTPTransport {
    private(set) var requests: [URLRequest] = []
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request)
        let url = try #require(request.url)
        if url.host == "offline.invalid" { throw URLError(.cannotConnectToHost) }
        let json = url.path == "/identity" ? #"{"MediaContainer":{"machineIdentifier":"owned"}}"#
            : #"{"MediaContainer":{"Directory":[{"key":"1","title":"Movies","type":"movie"}]}}"#
        let response = try #require(HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil))
        return (Data(json.utf8), response)
    }
}

private actor HeldServerConnector: PlexServerConnecting {
    private var pending: [String: CheckedContinuation<PlexServerConnectionResult, Error>] = [:]
    func connect(to server: PlexServerResource, identity: PlexClientIdentity, allowHTTP: Bool) async throws -> PlexServerConnectionResult {
        try await withCheckedThrowingContinuation { pending[server.id] = $0 }
    }

    func isPending(_ id: String) -> Bool { pending[id] != nil }
    func complete(_ server: PlexServerResource, identity: PlexClientIdentity) throws {
        let configuration = try server.configuration(connectionIndex: server.connections.count - 1, identity: identity)
        let libraries = [PlexLibrary(key: server.id, title: server.name, type: "movie")]
        pending.removeValue(forKey: server.id)?.resume(returning: PlexServerConnectionResult(configuration: configuration, libraries: libraries))
    }
}

@MainActor
struct DemoAutomaticConnectionTests {
    @Test func signingInConnectsTheOwnedServerAndPersistsTheSession() async throws {
        let transport = AutomaticConnectionTransport()
        let credentials = DemoMemoryCredentialStore()
        let session = makeSession(account: AutomaticAccount(), transport: transport, credentials: credentials)
        session.signIn()
        for _ in 0..<500 {
            if session.connectedServerID != nil || session.error != nil { break }
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(session.error == nil && session.api != nil && session.accountName == "Owner")
        #expect(session.connectedServerID == "owned" && session.connectedOrigin == "https://owned.invalid")
        #expect(session.serverID == "owned" && session.api?.configuration.machineIdentifier == "owned")
        #expect(session.libraries.map(\.key) == ["1"] && !session.isConnecting && !session.waitingForLogin)
        let requests = await transport.requests
        #expect(requests.contains { $0.url?.host == "owned.invalid" && $0.url?.path == "/library/sections" })
        #expect(requests.allSatisfy { $0.value(forHTTPHeaderField: "X-Plex-Token") == "owned-token" })
        let stored = try #require(credentials.load())
        #expect(stored.accountToken == "account-token" && stored.server?.machineIdentifier == "owned")
        session.signOut()
        #expect(credentials.load() == nil && !session.hasAccount)
    }

    @Test func cancelledServerSelectionCannotReplaceNewServerEvenWithNoncooperativeConnector() async throws {
        let connector = HeldServerConnector()
        let offline = DemoRoutingTransport([:])
        await offline.setFailing(true)
        let session = makeSession(transport: offline, connector: connector)
        let servers = try automaticTestServers()
        let shared = try #require(servers.first)
        let owned = try #require(servers.last)
        session.servers = servers
        session.selectedServerID = owned.id
        let previous = Task { await session.connectDiscovered() }
        for _ in 0..<1000 { if await connector.isPending(owned.id) { break }; await Task.yield() }
        #expect(await connector.isPending(owned.id))
        session.selectedServerID = shared.id
        let current = Task { await session.connectDiscovered() }
        for _ in 0..<1000 { if await connector.isPending(shared.id) { break }; await Task.yield() }
        #expect(await connector.isPending(shared.id))
        try await connector.complete(shared, identity: session.identity)
        await current.value
        try await connector.complete(owned, identity: session.identity)
        await previous.value
        #expect(session.connectedServerID == shared.id && session.libraries.map(\.key) == [shared.id])
        #expect(!session.isConnecting && session.error == nil)
        session.signOut()
    }
}
