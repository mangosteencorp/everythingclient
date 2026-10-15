import Foundation
@testable import Plex_Shared_Backend
import Testing

/// Answers by URL path (after the `/plex` proxy prefix) and records every request.
actor PlexRoutingTransport: PlexHTTPTransport {
    private(set) var requests: [URLRequest] = []
    private let routes: [String: String]
    var failing = false

    init(_ routes: [String: String]) { self.routes = routes }

    func setFailing(_ value: Bool) { failing = value }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request)
        if failing { throw URLError(.notConnectedToInternet) }
        let url = try #require(request.url)
        let path = url.path.hasPrefix("/plex") ? String(url.path.dropFirst(5)) : url.path
        let body = routes[path] ?? #"{"MediaContainer":{}}"#
        let response = try #require(HTTPURLResponse(url: url, statusCode: routes[path] == nil && request.httpMethod == "GET" ? 404 : 200, httpVersion: nil, headerFields: nil))
        return (Data(body.utf8), response)
    }
}

private func query(_ request: URLRequest?) -> [String: String] {
    guard let url = request?.url, let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems else { return [:] }
    return Dictionary(items.map { ($0.name, $0.value ?? "") }, uniquingKeysWith: { $1 })
}

private func service(_ transport: any PlexHTTPTransport, machineID: String? = "machine") throws -> PlexAPIService {
    let configuration = try PlexServerConfiguration(
        baseURL: #require(URL(string: "https://media.example/plex")), token: "server-token", identity: testIdentity(), machineIdentifier: machineID
    )
    return PlexAPIService(configuration: configuration, transport: transport)
}

struct PlexHubAndSearchTests {
    @Test func continueWatchingMergesOnDeckPerShowPreferringInProgressEpisode() async throws {
        let transport = PlexRoutingTransport(["/hubs": #"""
        {"MediaContainer":{"Hub":[
          {"hubIdentifier":"home.continue","title":"Continue","Metadata":[
            {"ratingKey":"m1","title":"Movie","type":"movie","viewOffset":10},
            {"ratingKey":"e1","title":"S1E1","type":"episode","grandparentRatingKey":"show"}]},
          {"hubIdentifier":"home.ondeck","title":"On Deck","Metadata":[
            {"ratingKey":"e2","title":"S1E2","type":"episode","grandparentRatingKey":"show","viewOffset":5},
            {"ratingKey":"m1","title":"Movie","type":"movie"}]},
          {"hubIdentifier":"empty","title":"Empty"}]}}
        """#])
        let api = try service(transport)
        let items = try await api.continueWatching(count: 5)
        #expect(items.map(\.ratingKey) == ["m1", "e2"])
        let request = await transport.requests.first
        #expect(query(request)["identifier"] == "home.continue,home.ondeck" && query(request)["count"] == "5")
        #expect(try await api.homeHubs(count: 3).map(\.id) == ["home.continue", "home.ondeck"])
    }

    @Test func sectionAndRelatedHubsUseScopedPaths() async throws {
        let transport = PlexRoutingTransport([:])
        let api = try service(transport)
        _ = try? await api.sectionHubs(sectionID: "4", count: 8)
        _ = try? await api.relatedHubs(ratingKey: "42", count: 3)
        let paths = await transport.requests.compactMap(\.url?.path)
        #expect(paths == ["/plex/hubs/sections/4", "/plex/hubs/metadata/42/related"])
    }

    @Test func searchFlattensSearchResultsAndLibraryQueryCarriesSortAndFilters() async throws {
        let transport = PlexRoutingTransport([
            "/library/search": #"{"MediaContainer":{"SearchResult":[{"score":1,"Metadata":{"ratingKey":"7","title":"Hit","type":"show"}},{"Metadata":{"title":"bad"}}]}}"#,
            "/library/sections/1/all": #"{"MediaContainer":{"Metadata":[]}}"#,
        ])
        let api = try service(transport)
        #expect(try await api.search(query: "hit").metadata.map(\.ratingKey) == ["7"])
        _ = try await api.items(sectionID: "1", page: PlexPagination(size: 10), query: PlexLibraryQuery(type: 1, sort: "addedAt:desc", filters: ["genre": "12", "unwatched": "1"]))
        let request = await transport.requests.last
        #expect(query(request) == ["type": "1", "sort": "addedAt:desc", "genre": "12", "unwatched": "1",
                                   "X-Plex-Container-Start": "0", "X-Plex-Container-Size": "10"])
    }

    @Test func directoriesCoverFiltersSortsAndFirstCharacters() async throws {
        let transport = PlexRoutingTransport([
            "/library/sections/1/filters": #"{"MediaContainer":{"Directory":[{"filter":"genre","filterType":"string","key":"/library/sections/1/genre","title":"Genre","type":"filter"}]}}"#,
            "/library/sections/1/sorts": #"{"MediaContainer":{"Directory":[{"key":"titleSort","descKey":"titleSort:desc","title":"Title","defaultDirection":"asc"}]}}"#,
            "/library/sections/1/firstCharacter": #"{"MediaContainer":{"Directory":[{"key":"A","title":"A","size":"3"}]}}"#,
        ])
        let api = try service(transport)
        #expect(try await api.filters(sectionID: "1").first?.filter == "genre")
        #expect(try await api.sorts(sectionID: "1").first?.descKey == "titleSort:desc")
        #expect(try await api.firstCharacters(sectionID: "1").first?.size == 3)
        #expect(try await api.filters(sectionID: "1").first.map { $0.title } == "Genre")
    }
}

struct PlexListMutationTests {
    @Test func collectionsAndPlaylistsUseServerURIsFromTheMachineIdentifier() async throws {
        let transport = PlexRoutingTransport(["/identity": #"{"MediaContainer":{"machineIdentifier":"fetched"}}"#])
        let configured = try service(transport)
        _ = try await configured.createCollection(sectionID: "1", title: "Faves", type: 1, ratingKeys: ["1", "2"])
        try await configured.addToPlaylist(id: "9", ratingKeys: ["3"])
        let requests = await transport.requests
        #expect(requests[0].httpMethod == "POST" && requests[0].url?.path == "/plex/library/collections")
        #expect(query(requests[0])["uri"] == "server://machine/com.plexapp.plugins.library/library/metadata/1,2")
        #expect(query(requests[0])["sectionId"] == "1" && query(requests[0])["smart"] == "0")
        #expect(requests[1].httpMethod == "PUT" && requests[1].url?.path == "/plex/playlists/9/items")

        let manual = try service(transport, machineID: nil)
        try await manual.addToCollection(collectionID: "5", ratingKeys: ["4"])
        let last = await transport.requests.suffix(2)
        #expect(last.first?.url?.path == "/plex/identity")
        #expect(query(last.last)["uri"] == "server://fetched/com.plexapp.plugins.library/library/metadata/4")
    }

    @Test func playlistEntriesAreRemovedAndMovedByPlaylistItemID() async throws {
        let transport = PlexRoutingTransport([:])
        let api = try service(transport)
        try await api.removeFromPlaylist(id: "9", playlistItemID: "900")
        try await api.movePlaylistItem(id: "9", playlistItemID: "900", afterPlaylistItemID: "901")
        try await api.removeFromCollection(collectionID: "5", ratingKey: "4")
        try await api.deletePlaylist(id: "9")
        let requests = await transport.requests
        #expect(requests.map { "\($0.httpMethod ?? "") \($0.url?.path ?? "")" } == [
            "DELETE /plex/playlists/9/items/900", "PUT /plex/playlists/9/items/900/move",
            "DELETE /plex/library/collections/5/items/4", "DELETE /plex/playlists/9",
        ])
        #expect(query(requests[1])["after"] == "901")
    }

    @Test func playQueuesDecodeAndStartFromAnEpisode() async throws {
        let transport = PlexRoutingTransport(["/playQueues": #"""
        {"MediaContainer":{"playQueueID":77,"playQueueVersion":"2","playQueueSelectedItemID":5,"playQueueShuffled":0,
          "Metadata":[{"ratingKey":"e1","title":"One","type":"episode"}]}}
        """#])
        let api = try service(transport)
        let queue = try await api.createPlayQueue(source: .path("/library/metadata/10/children"), shuffle: false, startingRatingKey: "e1")
        #expect(queue.id == "77" && queue.version == 2 && queue.selectedItemID == "5" && !queue.shuffled && queue.items.count == 1)
        let parameters = query(await transport.requests.last)
        #expect(parameters["uri"] == "server://machine/com.plexapp.plugins.library/library/metadata/10/children")
        #expect(parameters["key"] == "/library/metadata/e1" && parameters["continuous"] == "1")
        _ = try await api.createPlayQueue(source: .playlist("9"), shuffle: true, startingRatingKey: nil)
        let playlistQueue = await transport.requests.last
        #expect(query(playlistQueue)["playlistID"] == "9")
    }
}

struct PlexWatchStateAndMediaTests {
    @Test func watchStateRequestsMatchPlexWeb() async throws {
        let transport = PlexRoutingTransport(["/:/scrobble": "", "/:/unscrobble": ""])
        let api = try service(transport)
        try await api.markWatched(ratingKey: "42")
        try await api.markUnwatched(ratingKey: "42")
        let recorded = Date(timeIntervalSince1970: 1_700_000_000)
        try await api.reportTimeline(ratingKey: "42", state: .stopped, time: 5000, duration: 9000, recordedAt: recorded)
        try await api.rate(ratingKey: "42", rating: 14)
        try await api.rate(ratingKey: "42", rating: nil)
        try await api.removeFromContinueWatching(ratingKey: "42")
        let requests = await transport.requests
        #expect(query(requests[0]) == ["key": "42", "identifier": "com.plexapp.plugins.library"])
        #expect(requests[2].httpMethod == "POST")
        #expect(query(requests[2]) == ["ratingKey": "42", "key": "/library/metadata/42", "state": "stopped", "time": "5000",
                                       "duration": "9000", "offline": "1", "updated": "1700000000"])
        #expect(query(requests[3])["rating"] == "10.0" && query(requests[4])["rating"] == "-1")
        #expect(requests[5].httpMethod == "PUT" && query(requests[5])["ratingKey"] == "42")
    }

    @Test func streamRequestEncodesTheProfileAndKeepsTheTokenInHeaders() throws {
        let api = try service(PlexRoutingTransport([:]))
        let request = try api.streamRequest(PlexStreamOptions(ratingKey: "42", mediaIndex: 1, session: "abc", maxVideoBitrateKbps: 4000))
        let url = try #require(request.url)
        #expect(url.path == "/plex/video/:/transcode/universal/start.m3u8")
        #expect(url.absoluteString.contains("add-transcode-target%28type%3DvideoProfile"))
        #expect(!url.absoluteString.contains("server-token") && request.value(forHTTPHeaderField: "X-Plex-Token") == "server-token")
        let parameters = query(request)
        #expect(parameters["path"] == "/library/metadata/42" && parameters["mediaIndex"] == "1" && parameters["session"] == "abc")
        #expect(parameters["protocol"] == "hls" && parameters["maxVideoBitrate"] == "4000" && parameters["directStream"] == "0")
    }

    @Test func imageAndPartRequestsAreAuthenticatedAndNeverUseURLCache() throws {
        let api = try service(PlexRoutingTransport([:]))
        let image = try api.imageRequest(path: "/library/metadata/1/thumb/2", width: 200, height: 300)
        #expect(image.url?.path == "/plex/photo/:/transcode" && query(image)["url"] == "/library/metadata/1/thumb/2")
        #expect(image.cachePolicy == .reloadIgnoringLocalCacheData && image.value(forHTTPHeaderField: "X-Plex-Token") == "server-token")
        #expect(image.value(forHTTPHeaderField: "Accept") == "image/*")
        #expect(try api.directPlayRequest(part: PlexMediaPart(key: "/library/parts/1/file.mp4")).url?.path == "/plex/library/parts/1/file.mp4")
        #expect(throws: PlexAPIError.self) { try api.directPlayRequest(part: PlexMediaPart(key: "/x", exists: false)) }
        #expect(try api.previewThumbnailsRequest(partID: "8").url?.path == "/plex/library/parts/8/indexes/sd")
    }

    @Test func serverPreferencesProvideTheWatchedThreshold() async throws {
        let transport = PlexRoutingTransport([
            "/:/prefs": #"{"MediaContainer":{"Setting":[{"id":"LibraryVideoPlayedThreshold","value":80},{"id":"Flag","value":true}]}}"#,
            "/activities": #"{"MediaContainer":{"Activity":[{"uuid":"a","title":"Scan","progress":"40","cancellable":1}]}}"#,
        ])
        let api = try service(transport)
        #expect(try await api.watchedThreshold() == 0.8)
        #expect(try await api.serverPreferences().last?.value == "1")
        #expect(try await api.activities().first?.progress == 40)
    }
}

struct PlexModelTests {
    @Test func metadataDecodesTagsMarkersAndNestedOnDeckAndRoundTrips() throws {
        let item = try decodeFixture(PlexMetadata.self, #"""
        {"ratingKey":"1","title":"Show","type":"show","leafCount":"4","viewedLeafCount":4,"userRating":"7.5",
         "Genre":[{"id":3,"tag":"Drama"}],"Role":{"id":5,"tag":"Actor","role":"Lead"},
         "Marker":[{"type":"intro","startTimeOffset":"10","endTimeOffset":20}],
         "OnDeck":{"Metadata":{"ratingKey":"2","title":"Next","type":"episode"}}}
        """#)
        #expect(item.isWatched && item.userRating == 7.5 && item.genres.first?.tagID == "3" && item.roles.first?.role == "Lead")
        #expect(item.markers == [PlexMarker(type: "intro", startTimeOffset: 10, endTimeOffset: 20)])
        #expect(item.onDeck.first?.ratingKey == "2")
        let copy = try JSONDecoder().decode(PlexMetadata.self, from: JSONEncoder().encode(item))
        #expect(copy == item)
    }

    @Test func progressAndPosterFollowTheItemType() {
        let episode = PlexMetadata(ratingKey: "1", title: "E", type: "episode", duration: 100, viewOffset: 25, thumb: "/e")
        #expect(episode.progress == 0.25 && episode.posterPath == "/e" && !episode.isWatched)
    }
}

struct PlexOfflineTests {
    @Test func cachingTransportServesCachedResponsesOfflineAndOnNetworkFailure() async throws {
        let directory = URL.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let upstream = PlexRoutingTransport(["/library/sections": #"{"MediaContainer":{"Directory":[{"key":"1","title":"Movies","type":"movie"}]}}"#])
        let cache = PlexDiskResponseCache(directory: directory)
        let transport = PlexCachingTransport(upstream: upstream, cache: cache, scope: "machine")
        let api = try service(transport)
        #expect(try await api.libraries().count == 1)

        await upstream.setFailing(true)
        #expect(try await api.libraries().first?.title == "Movies")

        transport.isOffline = true
        let other = try PlexAPIService(configuration: PlexServerConfiguration(
            baseURL: #require(URL(string: "https://other-address.example/plex")), token: "t", identity: testIdentity()
        ), transport: transport)
        #expect(try await other.libraries().count == 1)
        await #expect(throws: PlexAPIError.offline) { try await api.items(sectionID: "1") }
        await #expect(throws: PlexAPIError.offline) { try await api.markWatched(ratingKey: "1") }
        #expect(await upstream.requests.count == 2)
    }

    @Test func artworkIsCachedFirstAndTheCacheNeverHoldsTheToken() async throws {
        let directory = URL.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let upstream = PlexStubTransport("png-bytes")
        let transport = PlexCachingTransport(upstream: upstream, cache: PlexDiskResponseCache(directory: directory), scope: "machine")
        let api = try PlexAPIService(configuration: testConfiguration(), transport: transport)
        #expect(try await api.imageData(path: "/library/metadata/1/thumb/9", width: 100) == Data("png-bytes".utf8))
        #expect(try await api.imageData(path: "/library/metadata/1/thumb/9", width: 100) == Data("png-bytes".utf8))
        #expect(await upstream.requests.count == 1)
        transport.isOffline = true
        #expect(try await api.imageData(path: "/library/metadata/1/thumb/9", width: 100) == Data("png-bytes".utf8))
        let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        #expect(files.count == 1)
        #expect(try files.allSatisfy { try String(bytes: Data(contentsOf: $0), encoding: .utf8)?.contains("server-token") != true })
    }

    @Test func otherServersAndMutationsAreNeverCached() async throws {
        let directory = URL.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let upstream = PlexRoutingTransport(["/library/sections": #"{"MediaContainer":{}}"#])
        let cache = PlexDiskResponseCache(directory: directory)
        _ = try await service(PlexCachingTransport(upstream: upstream, cache: cache, scope: "a")).libraries()
        let offline = PlexCachingTransport(upstream: upstream, cache: cache, scope: "b")
        offline.isOffline = true
        await #expect(throws: PlexAPIError.offline) { try await service(offline).libraries() }
    }

    @Test func watchQueueCollapsesActionsAndSyncsProgressPastTheThreshold() async throws {
        let file = URL.temporaryDirectory.appending(path: UUID().uuidString + ".json")
        defer { try? FileManager.default.removeItem(at: file) }
        let queue = PlexWatchSyncQueue(fileURL: file)
        await queue.enqueue(.progress(viewOffset: 100, duration: 1000), serverID: "s", ratingKey: "1")
        await queue.enqueue(.progress(viewOffset: 950, duration: 1000), serverID: "s", ratingKey: "1")
        await queue.enqueue(.watched, serverID: "s", ratingKey: "2")
        await queue.enqueue(.unwatched, serverID: "s", ratingKey: "2")
        await queue.enqueue(.watched, serverID: "other", ratingKey: "3")
        #expect(await queue.pending(serverID: "s").count == 2)
        #expect(await queue.localWatchedState(serverID: "s", ratingKey: "2") == false)
        #expect(await PlexWatchSyncQueue(fileURL: file).pending().count == 3)

        let transport = PlexRoutingTransport(["/:/prefs": #"{"MediaContainer":{"Setting":[]}}"#, "/:/scrobble": "", "/:/unscrobble": ""])
        #expect(await queue.sync(serverID: "s", using: try service(transport)) == 2)
        let requests = await transport.requests.compactMap { $0.url?.path }
        #expect(requests == ["/plex/:/prefs", "/plex/:/timeline", "/plex/:/scrobble", "/plex/:/unscrobble"])
        let timeline = await transport.requests[1]
        #expect(query(timeline)["offline"] == "1" && query(timeline)["time"] == "1000")
        #expect(await queue.pending().map(\.serverID) == ["other"])
    }

    @Test func failedActionsStayQueuedAndStopRetryingAfterTheLimit() async throws {
        let file = URL.temporaryDirectory.appending(path: UUID().uuidString + ".json")
        defer { try? FileManager.default.removeItem(at: file) }
        let queue = PlexWatchSyncQueue(fileURL: file)
        await queue.enqueue(.watched, serverID: "s", ratingKey: "1")
        let transport = PlexRoutingTransport([:])
        await transport.setFailing(true)
        let api = try service(transport)
        for _ in 0..<(PlexWatchSyncQueue.maxAttempts + 2) { await queue.sync(serverID: "s", using: api) }
        #expect(await queue.pending().first?.attempts == PlexWatchSyncQueue.maxAttempts)
        let scrobbles = await transport.requests.filter { $0.url?.path.hasSuffix("scrobble") == true }
        #expect(scrobbles.count == PlexWatchSyncQueue.maxAttempts)
    }
}

struct PlexEventTests {
    private struct Lines: PlexEventStreaming {
        let values: [String]
        func lines(for request: URLRequest) -> AsyncThrowingStream<String, Error> {
            AsyncThrowingStream { continuation in
                values.forEach { continuation.yield($0) }
                continuation.finish()
            }
        }
    }

    @Test func serverSentEventsAreGroupedByBlankLines() async throws {
        let source = Lines(values: ["event: playing", "data: {\"a\":1}", "", ": keepalive", "data: {\"b\":2}", ""])
        var events: [PlexServerEvent] = []
        for try await event in source.events(for: URLRequest(url: try #require(URL(string: "https://media.example")))) { events.append(event) }
        #expect(events.map(\.name) == ["playing", "message"])
        #expect(events.map { String(bytes: $0.data, encoding: .utf8) } == [#"{"a":1}"#, #"{"b":2}"#])
    }
}
