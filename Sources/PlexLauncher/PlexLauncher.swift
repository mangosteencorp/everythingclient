import Foundation
import Plex_Shared_Backend

/// The session lifecycle boundary for apps that use Plex. Browser UI and media playback belong to the app.
public protocol PlexLaunching: Sendable {
    /// The last successfully connected server.
    var connection: PlexConnection? { get async }
    /// Whether an account token is available, including a saved token that has not yet been revalidated.
    var hasAccount: Bool { get async }
    /// The saved account's display name.
    var accountName: String? { get async }
    /// Creates a PIN and browser URL without discarding an existing session.
    func beginSignIn() async throws -> PlexSignIn
    /// Polls once. Returns false while authorization is pending; true saves the new account session.
    func completeSignIn(pinID: String) async throws -> Bool
    /// Cancels a pending sign-in without signing out an existing account.
    func cancelSignIn() async
    /// Discovers servers using the current account token.
    func servers() async throws -> [PlexServerResource]
    /// Connects a chosen resource using its server-scoped token and saves the working address.
    func connect(to server: PlexServerResource, allowHTTP: Bool) async throws -> PlexConnection
    /// Discovers and connects the best server offering the requested content.
    func connectBest(content: PlexServerContent, allowHTTP: Bool) async throws -> PlexConnection
    /// Connects directly with a server token, independently of any signed-in account.
    func connect(baseURL: URL, token: String, name: String?, allowHTTP: Bool) async throws -> PlexConnection
    /// Verifies the saved server, rediscovering that same server if its saved address no longer works.
    /// Returns nil when neither a server nor an account session is saved.
    func resume(allowHTTP: Bool) async throws -> PlexConnection?
    /// Forgets this launcher's connection and stored credentials. Retained connection objects remain usable.
    func signOut() async
}

public extension PlexLaunching {
    func connect(to server: PlexServerResource) async throws -> PlexConnection {
        try await connect(to: server, allowHTTP: false)
    }

    func connectBest() async throws -> PlexConnection {
        try await connectBest(content: [.movies, .shows], allowHTTP: false)
    }

    func connectBest(content: PlexServerContent) async throws -> PlexConnection {
        try await connectBest(content: content, allowHTTP: false)
    }

    func connectBest(allowHTTP: Bool) async throws -> PlexConnection {
        try await connectBest(content: [.movies, .shows], allowHTTP: allowHTTP)
    }

    func connect(baseURL: URL, token: String, allowHTTP: Bool) async throws -> PlexConnection {
        try await connect(baseURL: baseURL, token: token, name: nil, allowHTTP: allowHTTP)
    }

    func connect(baseURL: URL, token: String, name: String? = nil) async throws -> PlexConnection {
        try await connect(baseURL: baseURL, token: token, name: name, allowHTTP: false)
    }

    func resume() async throws -> PlexConnection? {
        try await resume(allowHTTP: false)
    }
}

/// An object-oriented session coordinator over `Plex_Shared_Backend`.
/// Inject the existing backend protocols to test without a browser, Keychain or Plex server.
/// New connection and sign-in operations supersede older operations; superseded work throws `CancellationError`.
public actor PlexLauncher: PlexLaunching {
    public private(set) var connection: PlexConnection?
    public var hasAccount: Bool { session.accountToken != nil }
    public var accountName: String? { session.accountName }

    private let identity: PlexClientIdentity
    private let credentials: any PlexCredentialStoring
    private let transport: any PlexHTTPTransport
    private let account: any PlexAccountServing & PlexAccountProfileServing
    private let connector: any PlexServerConnecting
    private var session: PlexStoredSession
    private var pendingPINID: String?
    private var generation = UUID()

    private struct VerifiedConnection {
        let configuration: PlexServerConfiguration
        let libraries: [PlexLibrary]
        let name: String
    }

    /// Creates a launcher. Persist and reuse `identity.identifier` between app launches.
    /// - Parameters:
    ///   - credentials: Your chosen Keychain item or another secure credential store.
    ///   - transport: Shared by account calls, probes and the connected server API unless overridden below.
    ///   - account: Optional account API test double.
    ///   - connector: Optional connection-selection test double.
    public init(
        identity: PlexClientIdentity,
        credentials: any PlexCredentialStoring,
        transport: any PlexHTTPTransport = PlexURLSessionTransport(),
        account: (any PlexAccountServing & PlexAccountProfileServing)? = nil,
        connector: (any PlexServerConnecting)? = nil
    ) {
        self.identity = identity
        self.credentials = credentials
        self.transport = transport
        self.account = account ?? PlexAccountService(identity: identity, transport: transport)
        self.connector = connector ?? PlexServerConnector(transport: transport)
        session = credentials.load() ?? PlexStoredSession()
    }

    public func beginSignIn() async throws -> PlexSignIn {
        let operation = beginOperation()
        pendingPINID = nil
        let pin = try await account.createPIN()
        try check(operation)
        let url = try account.authorizationURL(code: pin.code)
        pendingPINID = pin.id
        return PlexSignIn(id: pin.id, code: pin.code, expiresIn: pin.expiresIn, authorizationURL: url)
    }

    public func completeSignIn(pinID: String) async throws -> Bool {
        guard pendingPINID == pinID else { throw PlexLauncherError.signInNotPending }
        let operation = beginOperation()
        let pin = try await account.pin(id: pinID)
        try check(operation)
        guard let token = pin.authToken else { return false }
        let name = try? await account.user(accountToken: token).title
        try check(operation)
        let signedIn = PlexStoredSession(accountToken: token, accountName: name)
        try credentials.save(signedIn)
        session = signedIn
        connection = nil
        pendingPINID = nil
        return true
    }

    public func cancelSignIn() {
        generation = UUID()
        pendingPINID = nil
    }

    public func servers() async throws -> [PlexServerResource] {
        guard let token = session.accountToken else { throw PlexLauncherError.signInRequired }
        let operation = generation
        let servers = try await account.servers(accountToken: token)
        try check(operation)
        return servers
    }

    public func connect(to server: PlexServerResource, allowHTTP: Bool = false) async throws -> PlexConnection {
        let operation = beginOperation()
        let result = try await connector.connect(to: server, identity: identity, allowHTTP: allowHTTP)
        try check(operation)
        return try install(result.configuration, libraries: result.libraries, name: server.name, session: session)
    }

    public func connectBest(
        content: PlexServerContent = [.movies, .shows], allowHTTP: Bool = false
    ) async throws -> PlexConnection {
        let operation = beginOperation()
        let servers = try await servers()
        let best = try await connector.connectBest(among: servers, identity: identity, content: content, allowHTTP: allowHTTP)
        try check(operation)
        return try install(best.connection.configuration, libraries: best.connection.libraries, name: best.server.name, session: session)
    }

    public func connect(
        baseURL: URL, token: String, name: String? = nil, allowHTTP: Bool = false
    ) async throws -> PlexConnection {
        let operation = beginOperation()
        let configuration = try PlexServerConfiguration(baseURL: baseURL, token: token, identity: identity)
        try requirePermittedScheme(configuration, allowHTTP: allowHTTP)
        let api = PlexAPIService(configuration: configuration, transport: transport)
        let info = try await api.serverInfo()
        try check(operation)
        guard let machineID = info.machineIdentifier, !machineID.isEmpty else { throw PlexAPIError.missingMachineIdentifier }
        let libraries = try await api.libraries()
        try check(operation)
        let identified = try PlexServerConfiguration(baseURL: baseURL, token: token, identity: identity, machineIdentifier: machineID)
        return try install(identified, libraries: libraries, name: name ?? info.friendlyName ?? baseURL.host() ?? baseURL.absoluteString, session: PlexStoredSession())
    }

    public func resume(allowHTTP: Bool = false) async throws -> PlexConnection? {
        let operation = beginOperation()
        guard let saved = credentials.load(), saved.server != nil || saved.accountToken != nil else { return nil }
        if let server = saved.server {
            let verified: VerifiedConnection
            do {
                verified = try await verify(server, allowHTTP: allowHTTP, operation: operation)
            } catch {
                try check(operation)
                guard let token = saved.accountToken, let machineID = server.machineIdentifier else { throw error }
                let servers = try await account.servers(accountToken: token)
                try check(operation)
                guard let resource = servers.first(where: { $0.id == machineID }) else { throw PlexAPIError.noReachableServer }
                let result = try await connector.connect(to: resource, identity: identity, allowHTTP: allowHTTP)
                try check(operation)
                return try install(result.configuration, libraries: result.libraries, name: resource.name, session: saved)
            }
            return try install(verified.configuration, libraries: verified.libraries, name: verified.name, session: saved)
        }
        guard let token = saved.accountToken else { return nil }
        let servers = try await account.servers(accountToken: token)
        try check(operation)
        let best = try await connector.connectBest(among: servers, identity: identity, allowHTTP: allowHTTP)
        try check(operation)
        return try install(best.connection.configuration, libraries: best.connection.libraries, name: best.server.name, session: saved)
    }

    public func signOut() {
        generation = UUID()
        pendingPINID = nil
        connection = nil
        session = PlexStoredSession()
        credentials.clear()
    }

    private func beginOperation() -> UUID {
        generation = UUID()
        return generation
    }

    private func check(_ operation: UUID) throws {
        try Task.checkCancellation()
        guard generation == operation else { throw CancellationError() }
    }

    private func requirePermittedScheme(_ configuration: PlexServerConfiguration, allowHTTP: Bool) throws {
        guard configuration.baseURL.scheme?.lowercased() == "https" || allowHTTP else { throw PlexAPIError.invalidConfiguration }
    }

    private func verify(
        _ server: PlexServerCredential, allowHTTP: Bool, operation: UUID
    ) async throws -> VerifiedConnection {
        let configuration = try server.configuration(identity: identity)
        try requirePermittedScheme(configuration, allowHTTP: allowHTTP)
        let api = PlexAPIService(configuration: configuration, transport: transport)
        let info = try await api.serverInfo()
        try check(operation)
        guard let machineID = info.machineIdentifier, !machineID.isEmpty else { throw PlexAPIError.missingMachineIdentifier }
        if let expected = server.machineIdentifier {
            guard machineID == expected else { throw PlexLauncherError.serverIdentityMismatch }
        }
        let libraries = try await api.libraries()
        try check(operation)
        return VerifiedConnection(configuration: configuration, libraries: libraries, name: info.friendlyName ?? server.name)
    }

    private func install(
        _ configuration: PlexServerConfiguration, libraries: [PlexLibrary], name: String, session: PlexStoredSession
    ) throws -> PlexConnection {
        var updated = session
        updated.server = configuration.credential(name: name)
        try credentials.save(updated)
        let connection = PlexConnection(name: name, accountName: updated.accountName, libraries: libraries, api: PlexAPIService(configuration: configuration, transport: transport))
        self.session = updated
        self.connection = connection
        return connection
    }
}
