import Foundation
import Plex_Shared_Backend

extension DemoSession {
    // MARK: - Servers

    func refreshServers() async {
        guard let token = accountToken else { return }
        await discover(token: token, preferring: selectedServerID)
    }

    /// Keeps `preferredID` when it is the user's choice and still listed; otherwise picks the best server.
    func discover(token: String, preferring preferredID: String?) async {
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
    func install(_ configuration: PlexServerConfiguration, libraries: [PlexLibrary], name: String, serverID: String?) {
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
}
