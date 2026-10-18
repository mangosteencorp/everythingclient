import Foundation
import Plex_Shared_Backend
@testable import PlexBackendDemo
import Testing

@MainActor
struct DemoFeatureTests {
    @Test func sampleLibraryCoversBrowsingDetailsAndDownloadPlans() async throws {
        let session = makeSession()
        session.loadSamples()
        #expect(session.isSample && session.libraries.count == 2 && session.serverID == "sample-server")
        let api = try #require(session.api)
        let movies = try await api.items(sectionID: "1")
        #expect(movies.metadata.count == 2 && movies.totalSize == 2)
        let movie = try await api.metadata(ratingKey: "100")
        #expect(movie.media.count == 2 && movie.markers.count == 2 && movie.roles.count == 2 && movie.genres.first?.tag == "Adventure")
        let plan = try await api.downloadPlan(ratingKey: movie.ratingKey)
        #expect(plan.parts.count == 1 && plan.parts.first?.subtitles.count == 1)
        #expect(plan.parts.first?.request.url?.query == nil)
        #expect(try await api.downloadPlan(ratingKey: "100", mediaIndex: 1).mediaIndex == 1)
        #expect(try await api.metadata(ratingKey: "200").onDeck.first?.ratingKey == "203")
        #expect(try await api.children(ratingKey: "200").metadata.first?.type == "season")
        #expect(try await api.grandchildren(ratingKey: "200").metadata.map(\.type) == ["episode", "episode"])
        #expect(try await api.search(query: "Sample").metadata.map(\.ratingKey) == ["100", "200"])
        session.signOut()
        #expect(session.api == nil && session.libraries.isEmpty && !session.isSample)
    }

    @Test func sampleHubsCollectionsPlaylistsAndFiltersMatchPlezyScreens() async throws {
        let session = makeSession()
        session.loadSamples()
        let api = try #require(session.api)
        #expect(try await api.continueWatching(count: 20).map(\.ratingKey) == ["100", "203"])
        #expect(try await api.homeHubs(count: 12).count == 2)
        #expect(try await api.sectionHubs(sectionID: "2", count: 12).first?.metadata.first?.ratingKey == "203")
        #expect(try await api.relatedHubs(ratingKey: "100", count: 10).map(\.title) == ["More Like This", "Collections"])
        #expect(try await api.collections(sectionID: "1").metadata.first?.title == "Sample Collection")
        #expect(try await api.collectionItems(collectionID: "300").metadata.count == 2)
        let playlist = try #require(try await api.playlists(type: "video").metadata.first)
        #expect(try await api.playlistItems(id: playlist.ratingKey).metadata.compactMap(\.playlistItemID) == ["9001", "9002"])
        let genre = try #require(try await api.filters(sectionID: "1").first { $0.filter == "genre" })
        let adventure = try #require(try await api.container(key: genre.key).directories.first)
        let filtered = try await api.items(sectionID: "1", query: PlexLibraryQuery(filters: ["genre": adventure.key]))
        #expect(filtered.metadata.map(\.ratingKey) == ["100"])
        #expect(try await api.sorts(sectionID: "1").count == 3)
        #expect(try await api.folders(sectionID: "1").directories.first?.title == "Feature films")
        #expect(try await api.createPlayQueue(source: .playlist("400"), shuffle: false, startingRatingKey: nil).items.count == 2)
        #expect(try await api.watchedThreshold() == 0.9)
    }

    @Test func pagedModelStopsAtTheServerTotalAndDeduplicates() async throws {
        let session = makeSession()
        session.loadSamples()
        let api = try #require(session.api)
        let model = PagedItemsModel(pageSize: 1)
        await model.load(api: api) { try await $0.items(sectionID: "1", page: $1) }
        #expect(model.items.count == 2 && model.hasLoaded && !model.canLoadMore && model.total == 2)
        await model.loadMore()
        #expect(model.items.count == 2)
        model.reset()
        #expect(model.items.isEmpty && !model.hasLoaded)
    }

    @Test func networkLogCapturesEveryCallAsRedactedCurlWhenEnabled() async throws {
        let session = makeSession()
        defer { session.logsNetworkCalls = false }
        session.loadSamples()
        let api = try #require(session.api)
        _ = try await api.libraries()
        #expect(session.networkLog.entries.isEmpty)
        session.logsNetworkCalls = true
        _ = try await api.continueWatching(count: 20)
        for _ in 0..<200 where session.networkLog.entries.isEmpty { try await Task.sleep(for: .milliseconds(10)) }
        let command = try #require(session.networkLog.entries.first?.command)
        #expect(command.hasPrefix("curl") && command.contains("/hubs?") && command.contains("X-Plex-Token: [redacted]"))
        #expect(!command.contains("sample'"))
    }

    @Test func responseInspectionRedactsNestedCredentials() throws {
        let session = makeSession()
        let data = Data(#"{"authToken":"never-show","nested":[{"access_token":"also-secret","title":"Visible"}]}"#.utf8)
        let result = session.formatted(PlexHTTPResult(data: data, statusCode: 200))
        #expect(!result.contains("never-show") && !result.contains("also-secret"))
        #expect(result.contains("Visible") && result.contains("[redacted]"))
    }

    @Test func completedFilesReloadButTraversalAndMissingFilesDoNot() throws {
        let directory = URL.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let item = PlexMetadata(ratingKey: "1", title: "Movie", type: "movie")
        let good = DemoDownload(id: UUID(), title: "Movie", fileName: "movie.mp4", status: .completed, serverID: "s", item: item)
        let missing = DemoDownload(id: UUID(), title: "Missing", fileName: "missing.mp4", status: .completed)
        let traversal = DemoDownload(id: UUID(), title: "Unsafe", fileName: "../movie.mp4", status: .completed)
        try Data("video".utf8).write(to: directory.appending(path: "movie.mp4"))
        try JSONEncoder().encode([good, missing, traversal]).write(to: directory.appending(path: "downloads.json"))
        let transfers = DemoTransfers(directory: directory)
        #expect(transfers.downloads == [good] && transfers.offlineItems.first?.item == item)
        #expect(!transfers.canRestart(good.id))
    }
}

private actor DelayedConnectionTransport: PlexHTTPTransport {
    private var continuation: CheckedContinuation<Void, Never>?
    private(set) var started = false
    private var released = false
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        started = true
        if !released { await withCheckedContinuation { continuation = $0 } }
        let url = try #require(request.url)
        let response = try #require(HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil))
        return (Data(#"{"MediaContainer":{"Directory":[]}}"#.utf8), response)
    }

    func release() { released = true; continuation?.resume(); continuation = nil }
}

@MainActor
struct DemoOfflineTests {
    @Test func staleConnectionCannotReplaceSampleSession() async throws {
        let transport = DelayedConnectionTransport()
        let session = makeSession(transport: transport)
        session.serverURL = "https://media.invalid"
        session.manualToken = "private-token"
        let connection = Task { await session.connectManual() }
        for _ in 0..<100 {
            if await transport.started { break }
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(await transport.started)
        session.loadSamples()
        await transport.release()
        await connection.value
        #expect(session.isSample && session.libraries.count == 2 && !session.busy)
        #expect(try await session.api?.metadata(ratingKey: "100").title == "The Sample Movie")
    }

    @Test func sampleContentStaysBrowsableOfflineAfterItWasOpened() async throws {
        let session = makeSession()
        session.loadSamples()
        let api = try #require(session.api)
        _ = try await api.continueWatching(count: 20)
        await session.setOffline(true)
        #expect(session.isOffline)
        #expect(try await api.continueWatching(count: 20).count == 2)
        await #expect(throws: PlexAPIError.offline) { try await api.items(sectionID: "2") }
    }

    @Test func restoredManualServerWorksFromCacheAndQueuedWatchChangesSyncWhenOnline() async throws {
        let storage = URL.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        defer { try? FileManager.default.removeItem(at: storage) }
        let credentials = DemoMemoryCredentialStore()
        let transport = DemoRoutingTransport([
            "/identity": #"{"MediaContainer":{"machineIdentifier":"home"}}"#,
            "/library/sections": #"{"MediaContainer":{"Directory":[{"key":"1","title":"Movies","type":"movie"}]}}"#,
        ])
        let first = makeSession(transport: transport, credentials: credentials, storage: storage)
        first.serverURL = "https://home.invalid"
        first.manualToken = "server-token"
        await first.connectManual()
        #expect(first.serverID == "home" && first.libraries.count == 1 && credentials.load()?.server?.machineIdentifier == "home")

        await transport.setFailing(true)
        let relaunched = makeSession(transport: transport, credentials: credentials, storage: storage)
        await relaunched.restore()
        #expect(relaunched.api != nil && relaunched.serverName == "home.invalid" && relaunched.libraries.map(\.title) == ["Movies"])

        await relaunched.setOffline(true)
        await relaunched.setWatched(true, ratingKey: "42")
        #expect(relaunched.pendingSync.map(\.ratingKey) == ["42"])
        #expect(relaunched.localWatchedState(of: PlexMetadata(ratingKey: "42", title: "", type: "movie")) == true)

        await transport.setFailing(false)
        await relaunched.setOffline(false)
        #expect(relaunched.pendingSync.isEmpty)
        let scrobble = await transport.requests.last { $0.url?.path == "/:/scrobble" }
        #expect(scrobble?.value(forHTTPHeaderField: "X-Plex-Token") == "server-token")
    }

    @Test func offlinePlaybackProgressIsQueuedForTheDownloadsServer() async throws {
        let session = makeSession()
        session.loadSamples()
        await session.setOffline(true)
        await session.reportProgress(ratingKey: "100", state: .playing, time: 1000, duration: 600_000, serverID: "elsewhere")
        #expect(session.pendingSync.isEmpty)
        await session.reportProgress(ratingKey: "100", state: .stopped, time: 300_000, duration: 600_000, serverID: "elsewhere")
        #expect(session.pendingSync.first?.serverID == "elsewhere")
        #expect(session.pendingSync.first?.kind == .progress(viewOffset: 300_000, duration: 600_000))
    }
}
