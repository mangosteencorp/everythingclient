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
    private(set) var api: PlexAPIService?
    private(set) var serverName = ""
    /// Cache and watch-sync scope: the machine identifier when known.
    private(set) var serverID = ""
    private(set) var connectedServerID: String?
    private(set) var connectedOrigin: String?
    /// The automatic pick that is connected, with the route and reply time that won; nil for a chosen server.
    private(set) var automaticPick: PlexBestServerConnection?
    private(set) var libraries: [PlexLibrary] = []
    private(set) var isConnecting = false
    private(set) var isSample = false
    private(set) var isOffline = false
    private(set) var pendingSync: [PlexPendingWatchAction] = []
    /// Changes whenever the connection or offline state changes so screens reload.
    private(set) var revision = UUID()
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

    @ObservationIgnored private let account: any PlexAccountServing & PlexAccountProfileServing
    @ObservationIgnored private let network: any PlexHTTPTransport
    @ObservationIgnored private let connector: any PlexServerConnecting
    @ObservationIgnored private let credentials: any PlexCredentialStoring
    @ObservationIgnored private let cache: any PlexResponseCaching
    @ObservationIgnored private let syncQueue: PlexWatchSyncQueue
    @ObservationIgnored private let storage: URL
    @ObservationIgnored private var cachingTransport: PlexCachingTransport?
    @ObservationIgnored private var accountToken: String?
    @ObservationIgnored private var secrets: [String] = []
    @ObservationIgnored private var loginTask: Task<Void, Never>?
    @ObservationIgnored private var loginGeneration = UUID()
    @ObservationIgnored private var operationGeneration = UUID()
    @ObservationIgnored private var connectionTask: Task<Void, Never>?
    @ObservationIgnored private var connectionGeneration = UUID()

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

    private func persist() {
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

    // MARK: - Servers

    func refreshServers() async {
        guard let token = accountToken else { return }
        await discover(token: token, preferring: selectedServerID)
    }

    /// Keeps `preferredID` when it is the user's choice and still listed; otherwise picks the best server.
    private func discover(token: String, preferring preferredID: String?) async {
        do {
            let found = try await account.servers(accountToken: token)
            guard accountToken == token else { return }
            servers = found
            if !found.contains(where: { $0.id == preferredID }) { picksServerAutomatically = true }
            await connectDiscovered()
        } catch is CancellationError {
        } catch {
            // Plezy keeps showing cached content when the account service is unreachable.
            if api != nil { await setOffline(true) } else { self.error = Self.message(for: error) }
        }
    }

    /// Connects the chosen server, or picks the best one again for nil (Automatic).
    func selectServer(_ id: String?) {
        guard id != (picksServerAutomatically ? nil : selectedServerID) || connectedServerID == nil else { return }
        picksServerAutomatically = id == nil
        if let id { selectedServerID = id }
        startConnection()
    }

    func connectDiscovered() async {
        startConnection()
        await connectionTask?.value
    }

    private func startConnection() {
        let automatic = picksServerAutomatically
        let candidates = automatic ? servers : selectedServer.map { [$0] } ?? []
        guard let chosen = candidates.first else { return }
        connectionGeneration = UUID()
        connectionTask?.cancel()
        error = nil
        isConnecting = true
        let generation = connectionGeneration
        let allowHTTP = allowHTTP
        connectionTask = Task {
            defer { if connectionGeneration == generation { isConnecting = false } }
            do {
                let pick = try await automatic ? connector.connectBest(among: candidates, identity: identity, allowHTTP: allowHTTP) : nil
                let server = pick?.server ?? chosen
                let result = if let pick { pick.connection } else { try await connector.connect(to: server, identity: identity, allowHTTP: allowHTTP) }
                try Task.checkCancellation()
                guard connectionGeneration == generation, automatic || selectedServerID == server.id else { return }
                isSample = false
                selectedServerID = server.id
                install(result.configuration, libraries: result.libraries, name: server.name, serverID: server.id)
                automaticPick = pick
                connectedServerID = server.id
                persist()
                // Re-read sections through the caching API so they are available offline after relaunch.
                if let libraries = try? await api?.libraries(), connectionGeneration == generation { self.libraries = libraries }
                await syncNow()
            } catch is CancellationError {
            } catch {
                guard connectionGeneration == generation else { return }
                if candidates.contains(where: { $0.id == serverID }) { await setOffline(true) } else { self.error = Self.message(for: error) }
            }
        }
    }

    func connectManual() async {
        await perform {
            guard let url = URL(string: self.serverURL.trimmingCharacters(in: .whitespacesAndNewlines)) else {
                throw PlexAPIError.invalidConfiguration
            }
            let configuration = try PlexServerConfiguration(baseURL: url, token: self.manualToken, identity: self.identity)
            guard configuration.baseURL.scheme?.lowercased() == "https" || self.allowHTTP else {
                throw PlexAPIError.invalidConfiguration
            }
            self.disconnect()
            let startingRevision = self.revision
            let machineID = try? await PlexAPIService(configuration: configuration, transport: self.network).machineIdentifier()
            guard self.revision == startingRevision else { throw CancellationError() }
            let identified = try PlexServerConfiguration(
                baseURL: url, token: self.manualToken, identity: self.identity, machineIdentifier: machineID
            )
            self.install(identified, libraries: [], name: url.host() ?? "Plex", serverID: machineID)
            let installed = self.revision
            do {
                // /identity needs no token; listing sections proves the token works and fills the offline cache.
                let libraries = try await self.api?.libraries() ?? []
                guard self.revision == installed else { throw CancellationError() }
                self.libraries = libraries
            } catch {
                if self.revision == installed { self.disconnect() }
                throw error
            }
            self.manualToken = ""
            self.persist()
        }
    }

    /// Builds the API on a caching transport scoped to this server.
    private func install(_ configuration: PlexServerConfiguration, libraries: [PlexLibrary], name: String, serverID: String?) {
        let scope = serverID ?? configuration.machineIdentifier ?? configuration.baseURL.host() ?? "server"
        let transport = PlexCachingTransport(upstream: network, cache: cache, scope: scope)
        cachingTransport = transport
        let service = PlexAPIService(configuration: configuration, transport: transport)
        if let token = try? service.resourceRequest(path: "/").value(forHTTPHeaderField: "X-Plex-Token") { secrets.append(token) }
        api = service
        isOffline = false
        self.libraries = libraries
        serverName = name
        self.serverID = scope
        connectedOrigin = configuration.baseURL.absoluteString
        revision = UUID()
        Task { await refreshPendingSync() }
    }

    func disconnect() {
        connectionGeneration = UUID()
        connectionTask?.cancel()
        connectionTask = nil
        isConnecting = false
        api = nil
        cachingTransport = nil
        libraries = []
        connectedServerID = nil
        connectedOrigin = nil
        automaticPick = nil
        serverName = ""
        serverID = ""
        isSample = false
        isOffline = false
        revision = UUID()
    }

    /// Synthetic content through the same caching transport, so offline mode can be tried without a server.
    func loadSamples() {
        cancelLogin()
        disconnect()
        guard let url = URL(string: "https://sample.invalid"),
              let configuration = try? PlexServerConfiguration(
                  baseURL: url, token: "sample", identity: identity, machineIdentifier: "sample-server"
              ) else { return }
        isSample = true
        let transport = PlexCachingTransport(
            upstream: PlexCurlLoggingTransport(upstream: DemoFixtureTransport(), logger: curlLogger), cache: cache, scope: "sample-server"
        )
        cachingTransport = transport
        api = PlexAPIService(configuration: configuration, transport: transport)
        serverName = String(localized: "Sample server")
        serverID = "sample-server"
        libraries = [PlexLibrary(key: "1", title: String(localized: "Movies"), type: "movie"),
                     PlexLibrary(key: "2", title: String(localized: "TV Shows"), type: "show")]
        revision = UUID()
        Task { await refreshPendingSync() }
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

    // MARK: - Offline and watch sync

    /// Cache-only browsing. Going back online reconnects when needed and pushes queued watch changes.
    func setOffline(_ offline: Bool) async {
        isOffline = offline
        cachingTransport?.isOffline = offline
        revision = UUID()
        guard !offline else { return }
        if hasAccount, connectedServerID == nil, !isSample { await refreshServers() } else { await syncNow() }
    }

    func syncNow() async {
        guard let api, !isOffline else { return }
        _ = await syncQueue.sync(serverID: serverID, using: api)
        await refreshPendingSync()
    }

    func refreshPendingSync() async {
        pendingSync = await syncQueue.pending()
    }

    func localWatchedState(of item: PlexMetadata) -> Bool? { localWatchedState(serverID: serverID, ratingKey: item.ratingKey) }

    /// The watched state decided by a queued action, if any; progress-only actions don't decide it.
    func localWatchedState(serverID: String?, ratingKey: String) -> Bool? {
        switch pendingSync.last(where: { $0.serverID == serverID && $0.ratingKey == ratingKey })?.kind {
        case .watched: true
        case .unwatched: false
        default: nil
        }
    }

    /// Online changes go to the server; offline (or failed) changes are queued like Plezy's offline watch sync.
    func setWatched(_ watched: Bool, ratingKey: String, serverID: String? = nil) async {
        let target = serverID ?? self.serverID
        if let api, !isOffline, target == self.serverID {
            do {
                if watched { try await api.markWatched(ratingKey: ratingKey) } else { try await api.markUnwatched(ratingKey: ratingKey) }
                revision = UUID()
                return
            } catch let failure where !Self.isConnectivityFailure(failure) {
                error = Self.message(for: failure)
                return
            } catch {}
        }
        await syncQueue.enqueue(watched ? .watched : .unwatched, serverID: target, ratingKey: ratingKey)
        await refreshPendingSync()
    }

    /// Player progress. Playing/paused updates are best effort; a stopped position is queued if it cannot be sent.
    func reportProgress(
        ratingKey: String, state: PlexPlaybackState, time: Int64, duration: Int64?, serverID: String? = nil
    ) async {
        let target = serverID ?? self.serverID
        if let api, !isOffline, target == self.serverID {
            do {
                try await api.reportTimeline(ratingKey: ratingKey, state: state, time: time, duration: duration, recordedAt: nil)
                return
            } catch {}
        }
        guard state == .stopped, time > 0 else { return }
        await syncQueue.enqueue(.progress(viewOffset: time, duration: duration), serverID: target, ratingKey: ratingKey)
        await refreshPendingSync()
    }

    func clearCache() async {
        await cache.removeAll()
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
