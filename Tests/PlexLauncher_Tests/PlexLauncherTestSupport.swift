import Foundation
import Plex_Shared_Backend
import Synchronization
import Testing

func launcherIdentity() throws -> PlexClientIdentity {
    try PlexClientIdentity(identifier: "saved-client", product: "Launcher tests", version: "1", platform: "iOS")
}

func launcherConfiguration(
    baseURL: String = "https://old.example", token: String = "saved-server-token", machineID: String? = "saved-server"
) throws -> PlexServerConfiguration {
    try PlexServerConfiguration(baseURL: #require(URL(string: baseURL)), token: token, identity: launcherIdentity(), machineIdentifier: machineID)
}

func launcherResource(
    id: String = "saved-server", name: String = "Home", token: String = "fresh-server-token"
) throws -> PlexServerResource {
    try decodeLauncherFixture(PlexServerResource.self, [
        "clientIdentifier": id, "name": name, "provides": "server", "accessToken": token,
        "connections": [["uri": "https://fresh.example"]],
    ])
}

func decodeLauncherFixture<Value: Decodable>(_ type: Value.Type, _ value: Any) throws -> Value {
    try JSONDecoder().decode(type, from: JSONSerialization.data(withJSONObject: value))
}

final class LauncherCredentialStore: PlexCredentialStoring {
    enum Failure: Error, Equatable { case rejected }
    struct State {
        var session: PlexStoredSession?
        var writes = 0
        var rejectsWrites = false
    }

    private let state: Mutex<State>
    init(_ session: PlexStoredSession? = nil, rejectsWrites: Bool = false) {
        state = Mutex(State(session: session, rejectsWrites: rejectsWrites))
    }

    var writes: Int { state.withLock { $0.writes } }
    func load() -> PlexStoredSession? { state.withLock { $0.session } }
    func save(_ session: PlexStoredSession) throws {
        try state.withLock {
            guard !$0.rejectsWrites else { throw Failure.rejected }
            $0.session = session
            $0.writes += 1
        }
    }

    func clear() { state.withLock { $0.session = nil } }
}

actor LauncherTransport: PlexHTTPTransport {
    private let body: @Sendable (URLRequest) throws -> String
    private(set) var requests: [URLRequest] = []

    init(_ body: @escaping @Sendable (URLRequest) throws -> String = { _ in throw URLError(.notConnectedToInternet) }) {
        self.body = body
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request)
        let data = try Data(body(request).utf8)
        let url = try #require(request.url)
        let response = try #require(HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil))
        return (data, response)
    }
}

actor LauncherGate {
    private var entryCount = 0
    private var isOpen = false
    private var entryWaiters: [(count: Int, continuation: CheckedContinuation<Void, Never>)] = []
    private var blocked: [CheckedContinuation<Void, Never>] = []

    func pause() async {
        entryCount += 1
        entryWaiters.filter { $0.count <= entryCount }.forEach { $0.continuation.resume() }
        entryWaiters.removeAll { $0.count <= entryCount }
        guard !isOpen else { return }
        await withCheckedContinuation { blocked.append($0) }
    }

    func waitUntilEntered(_ count: Int = 1) async {
        guard entryCount < count else { return }
        await withCheckedContinuation { entryWaiters.append((count, $0)) }
    }

    func open() {
        isOpen = true
        blocked.forEach { $0.resume() }
        blocked = []
    }
}

actor LauncherAccount: PlexAccountServing, PlexAccountProfileServing {
    private let resources: [PlexServerResource]
    private var pins: [PlexPIN]
    private let pending: PlexPIN
    private let profile: PlexAccountUser
    private let pinGate: LauncherGate?
    private(set) var createCount = 0
    private(set) var discoveryTokens: [String] = []

    init(resources: [PlexServerResource] = [], pinTokens: [String?] = [nil], pinGate: LauncherGate? = nil) throws {
        self.resources = resources
        self.pinGate = pinGate
        pending = try decodeLauncherFixture(PlexPIN.self, ["id": "pin-id", "code": "pin-code", "expiresIn": 300])
        pins = try pinTokens.map { token in
            try decodeLauncherFixture(PlexPIN.self, ["id": "pin-id", "code": "pin-code", "authToken": token as Any? ?? NSNull()])
        }
        profile = try decodeLauncherFixture(PlexAccountUser.self, ["id": "user-id", "title": "Alex"])
    }

    func createPIN() async throws -> PlexPIN {
        createCount += 1
        return pending
    }

    func pin(id _: String) async throws -> PlexPIN {
        await pinGate?.pause()
        return pins.isEmpty ? pending : pins.removeFirst()
    }

    nonisolated func authorizationURL(code _: String) throws -> URL {
        try #require(URL(string: "https://app.plex.tv/auth#?code=pin-code"))
    }

    func servers(accountToken: String) async throws -> [PlexServerResource] {
        discoveryTokens.append(accountToken)
        return resources
    }

    func user(accountToken _: String) async throws -> PlexAccountUser { profile }
    func homeUsers(accountToken _: String) async throws -> [PlexAccountUser] { [] }
    func switchUser(uuid _: String, pin _: String?, accountToken _: String) async throws -> PlexAccountSession {
        throw PlexAPIError.invalidConfiguration
    }
}

actor LauncherConnector: PlexServerConnecting {
    private let gate: LauncherGate?
    private(set) var connectedIDs: [String] = []
    private(set) var httpChoices: [Bool] = []
    private(set) var contentChoices: [PlexServerContent] = []

    init(gate: LauncherGate? = nil) { self.gate = gate }

    func connect(to server: PlexServerResource, identity: PlexClientIdentity, allowHTTP: Bool) async throws -> PlexServerConnectionResult {
        connectedIDs.append(server.id)
        httpChoices.append(allowHTTP)
        await gate?.pause()
        return try PlexServerConnectionResult(configuration: server.configuration(connectionIndex: 0, identity: identity), libraries: [PlexLibrary(key: "1", title: "Movies", type: "movie")])
    }

    func connectBest(
        among servers: [PlexServerResource], identity: PlexClientIdentity, content: PlexServerContent, allowHTTP: Bool,
        gracePeriod _: Duration
    ) async throws -> PlexBestServerConnection {
        contentChoices.append(content)
        guard let server = servers.first else { throw PlexAPIError.noReachableServer }
        return try await PlexBestServerConnection(server: server, connection: connect(to: server, identity: identity, allowHTTP: allowHTTP), latency: .zero)
    }
}

let launcherServerInfo = #"{"MediaContainer":{"friendlyName":"Home","machineIdentifier":"saved-server"}}"#
let launcherSections = #"{"MediaContainer":{"Directory":[{"key":"1","title":"Movies","type":"movie"}]}}"#
