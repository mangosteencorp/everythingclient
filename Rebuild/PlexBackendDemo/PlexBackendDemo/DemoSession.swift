import Foundation
import Observation
import Plex_Shared_Backend
import Synchronization

/// App-wide Plex state, mirroring Plezy: PIN sign-in, server discovery and automatic connection,
/// a persisted session, a response cache that keeps browsing working offline, and queued watch sync.
@MainActor
@Observable
final class DemoSession {
    // Account and sign-in
    private(set) var hasAccount = false
    private(set) var accountName = ""
    private(set) var homeUsers: [PlexAccountUser] = []
    var servers: [PlexServerResource] = []
    var selectedServerID = ""
    /// Automatic in the server picker: discovery connects the best server. Choosing a server turns it off.
    var picksServerAutomatically = true
    private(set) var pinCode = ""
    private(set) var authorizationURL: URL?
    private(set) var waitingForLogin = false
    // Connection
    var api: PlexAPIService?
    var serverName = ""
    /// Cache and watch-sync scope: the machine identifier when known.
    var serverID = ""
    var connectedServerID: String?
    var connectedOrigin: String?
    /// The automatic pick that is connected, with the route and reply time that won; nil for a chosen server.
    var automaticPick: PlexBestServerConnection?
    var libraries: [PlexLibrary] = []
    var isConnecting = false
    var isSample = false
    var isOffline = false
    var pendingSync: [PlexPendingWatchAction] = []
    /// Changes whenever the connection or offline state changes so screens reload.
    var revision = UUID()
    private(set) var busy = false
    var error: String?
    var allowHTTP = false
    var serverURL = ""
    var manualToken = ""
    let transfers: DemoTransfers
    let identity: PlexClientIdentity
    /// Shared switch for logging every network call as `curl`; `networkLog` keeps the recent ones for display.
    @ObservationIgnored let curlLogger: PlexCurlLogger
    let networkLog: DemoNetworkLog
    var logsNetworkCalls: Bool {
        didSet {
            curlLogger.isEnabled = logsNetworkCalls
            UserDefaults.standard.set(logsNetworkCalls, forKey: "plex-demo-curl-logging")
        }
    }

    var redactsNetworkLog = true {
        didSet { curlLogger.redactsCredentials = redactsNetworkLog }
    }

    @ObservationIgnored let account: any PlexAccountServing & PlexAccountProfileServing
    @ObservationIgnored let network: any PlexHTTPTransport
    @ObservationIgnored let connector: any PlexServerConnecting
    @ObservationIgnored private let credentials: any PlexCredentialStoring
    @ObservationIgnored let cache: any PlexResponseCaching
    @ObservationIgnored let syncQueue: PlexWatchSyncQueue
    @ObservationIgnored private let storage: URL
    @ObservationIgnored var cachingTransport: PlexCachingTransport?
    @ObservationIgnored private(set) var accountToken: String?
    @ObservationIgnored var secrets: [String] = []
    @ObservationIgnored private var loginTask: Task<Void, Never>?
    @ObservationIgnored private var loginGeneration = UUID()
    @ObservationIgnored private var operationGeneration = UUID()
    @ObservationIgnored var connectionTask: Task<Void, Never>?
    @ObservationIgnored var connectionGeneration = UUID()

    init(
        account: (any PlexAccountServing & PlexAccountProfileServing)? = nil,
        serverTransport: any PlexHTTPTransport = PlexURLSessionTransport(),
        connector: (any PlexServerConnecting)? = nil,
        credentials: any PlexCredentialStoring = PlexKeychainCredentialStore(service: "com.prototype.PlexBackendDemo"),
        storage: URL = .applicationSupportDirectory.appending(path: "PlexBackendDemo", directoryHint: .isDirectory)
    ) {
        let defaults = UserDefaults.standard
        let identifier = defaults.string(forKey: "plex-demo-client-id") ?? UUID().uuidString
        defaults.set(identifier, forKey: "plex-demo-client-id")
        // These fixed identity fields and a generated UUID always satisfy header validation.
        do {
            identity = try PlexClientIdentity(identifier: identifier, product: "Plex Backend Demo", version: "1", platform: "iOS")
        } catch {
            preconditionFailure("Invalid demo client identity")
        }
        let log = DemoNetworkLog()
        let logging = defaults.bool(forKey: "plex-demo-curl-logging")
        let logger = PlexCurlLogger(isEnabled: logging) { command in
            PlexCurlLogger.systemSink(command)
            Task { @MainActor in log.append(command) }
        }
        networkLog = log
        curlLogger = logger
        logsNetworkCalls = logging
        let network = PlexCurlLoggingTransport(upstream: serverTransport, logger: logger)
        self.network = network
        self.account = account ?? PlexAccountService(identity: identity, transport: network)
        self.connector = connector ?? PlexServerConnector(transport: network)
        self.credentials = credentials
        self.storage = storage
        cache = PlexDiskResponseCache(directory: storage.appending(path: "ResponseCache"))
        syncQueue = PlexWatchSyncQueue(fileURL: storage.appending(path: "WatchSync.json"))
        transfers = DemoTransfers(directory: storage.appending(path: "Downloads", directoryHint: .isDirectory))
        transfers.willStart = { logger.log($0) }
        // Earlier builds kept artwork in a URLCache, which also stored the token header. Artwork now lives in the
        // token-free response cache, so remove that folder.
        try? FileManager.default.removeItem(at: storage.appending(path: "ImageCache"))
    }

    var selectedServer: PlexServerResource? { servers.first { $0.id == selectedServerID } }

    // MARK: - Restore and persistence

    /// Reopens the saved server immediately (its cache works offline), then rediscovers fresh addresses.
    func restore() async {
        guard api == nil, !isSample, let stored = credentials.load() else { return }
        accountToken = stored.accountToken
        hasAccount = stored.accountToken != nil
        accountName = stored.accountName ?? ""
        secrets = [stored.accountToken].compactMap { $0 }
        if let saved = stored.server, let configuration = try? saved.configuration(identity: identity) {
            install(configuration, libraries: [], name: saved.name, serverID: saved.machineIdentifier)
            // Show cached sections at once instead of waiting for a saved address that may be unreachable.
            cachingTransport?.isOffline = true
            libraries = (try? await api?.libraries()) ?? []
            cachingTransport?.isOffline = false
        }
        if let token = accountToken {
            await discover(token: token, preferring: stored.server?.machineIdentifier)
        } else if let api {
            do { libraries = try await api.libraries() } catch { await setOffline(true) }
        }
    }

    func persist() {
        guard !isSample else { return }
        let server = api.map { $0.configuration.credential(name: serverName) }
        try? credentials.save(PlexStoredSession(accountToken: accountToken, accountName: accountName, server: server))
    }

    // MARK: - Sign-in

    func signIn() {
        signOut()
        waitingForLogin = true
        let generation = loginGeneration
        loginTask = Task {
            do {
                let pin = try await account.createPIN()
                try Task.checkCancellation()
                guard generation == loginGeneration else { return }
                pinCode = pin.code
                authorizationURL = try account.authorizationURL(code: pin.code)
                let deadline = Date().addingTimeInterval(TimeInterval(min(pin.expiresIn ?? 300, 900)))
                while Date() < deadline {
                    try await Task.sleep(for: .seconds(2))
                    let checked = try await account.pin(id: pin.id)
                    try Task.checkCancellation()
                    guard generation == loginGeneration else { return }
                    if let token = checked.authToken {
                        finishLogin(token: token)
                        accountName = (try? await account.user(accountToken: token).title) ?? ""
                        guard generation == loginGeneration else { return }
                        persist()
                        await discover(token: token, preferring: nil)
                        return
                    }
                }
                throw PlexAPIError.pinExpired
            } catch is CancellationError {
                // Cancelling login is an ordinary user action.
            } catch {
                guard generation == loginGeneration else { return }
                self.error = Self.message(for: error)
                cancelLogin()
            }
        }
    }

    private func finishLogin(token: String) {
        accountToken = token
        secrets = [token]
        hasAccount = true
        waitingForLogin = false
        authorizationURL = nil
        pinCode = ""
    }

    func cancelLogin() {
        loginGeneration = UUID()
        loginTask?.cancel()
        loginTask = nil
        waitingForLogin = false
        authorizationURL = nil
        pinCode = ""
    }

    /// Forgets credentials and the connection. Downloads and queued watch changes stay on the device.
    func signOut() {
        operationGeneration = UUID()
        busy = false
        cancelLogin()
        transfers.cancelActive()
        disconnect()
        credentials.clear()
        servers = []
        homeUsers = []
        accountName = ""
        accountToken = nil
        hasAccount = false
        manualToken = ""
        secrets = []
        error = nil
    }

    // MARK: - Home profiles

    func loadProfiles() async {
        await perform {
            guard let token = self.accountToken else { throw PlexAPIError.invalidConfiguration }
            let name = try await self.account.user(accountToken: token).title
            let users = try await self.account.homeUsers(accountToken: token)
            self.accountName = name
            self.homeUsers = users
        }
    }

    func switchProfile(uuid: String, pin: String) async {
        await perform {
            guard let token = self.accountToken else { throw PlexAPIError.invalidConfiguration }
            let switched = try await self.account.switchUser(uuid: uuid, pin: pin, accountToken: token)
            self.transfers.cancelActive()
            self.disconnect()
            self.finishLogin(token: switched.authToken)
            self.accountName = self.homeUsers.first { $0.uuid == uuid }?.title ?? ""
            self.persist()
            await self.discover(token: switched.authToken, preferring: nil)
        }
    }

    // MARK: - Helpers

    func perform(_ work: () async throws -> Void) async {
        guard !busy else { return }
        let generation = UUID()
        operationGeneration = generation
        busy = true
        error = nil
        defer { if operationGeneration == generation { busy = false } }
        do { try await work() } catch is CancellationError {} catch {
            if operationGeneration == generation { self.error = Self.message(for: error) }
        }
    }

    /// Runs a server action and reports failures through the shared alert.
    func run(_ work: (PlexAPIService) async throws -> Void) async -> Bool {
        guard let api else { return false }
        do {
            try await work(api)
            return true
        } catch is CancellationError {
            return false
        } catch {
            self.error = Self.message(for: error)
            return false
        }
    }

    func redacted(_ text: String) -> String {
        secrets.filter { !$0.isEmpty }.reduce(text) { $0.replacingOccurrences(of: $1, with: "[redacted]") }
    }

    nonisolated static func isConnectivityFailure(_ error: any Error) -> Bool {
        error is URLError || error as? PlexAPIError == .offline || error as? PlexAPIError == .noReachableServer
    }
}

/// The most recent `curl` commands, newest first.
@MainActor
@Observable
final class DemoNetworkLog {
    struct Entry: Identifiable, Equatable {
        let id = UUID()
        let date = Date()
        let command: String
    }

    private(set) var entries: [Entry] = []

    func append(_ command: String) {
        entries.insert(Entry(command: command), at: 0)
        if entries.count > 200 { entries.removeLast(entries.count - 200) }
    }

    func clear() { entries = [] }
}

/// Keeps a session in memory only; used by previews and tests.
nonisolated final class DemoMemoryCredentialStore: PlexCredentialStoring {
    private let session: Mutex<PlexStoredSession?>
    init(_ session: PlexStoredSession? = nil) { self.session = Mutex(session) }
    func load() -> PlexStoredSession? { session.withLock { $0 } }
    func save(_ session: PlexStoredSession) throws { self.session.withLock { $0 = session } }
    func clear() { session.withLock { $0 = nil } }
}

extension DemoSession {
    /// A sample-mode session for previews.
    static func preview() -> DemoSession {
        let session = DemoSession(
            credentials: DemoMemoryCredentialStore(),
            storage: .temporaryDirectory.appending(path: "PlexBackendDemoPreview", directoryHint: .isDirectory)
        )
        session.loadSamples()
        return session
    }
}
