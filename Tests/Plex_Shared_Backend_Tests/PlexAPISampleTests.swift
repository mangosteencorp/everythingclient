import Foundation
@testable import Plex_Shared_Backend
import Testing

// One test per API row in Sources/Plex_Shared_Backend/README.md (here and in PlexAPISampleTests+Server.swift):
// each checks the exact request and decodes the README's sample response. Keep fixtures and samples identical.

/// `METHOD url`, with the test server's origin and proxy prefix removed so it reads like the README table.
func requestLine(_ request: URLRequest) -> String {
    "\(request.httpMethod ?? "") " + (request.url?.absoluteString ?? "").replacingOccurrences(of: "https://media.example/plex", with: "")
}

/// Runs `call` against a server that answers `json`; returns its result and every request it sent.
func stubbed<Value>(
    _ json: String = "", machineID: String? = "machine", _ call: (PlexAPIService) async throws -> Value
) async throws -> (value: Value, requests: [String]) {
    let transport = PlexStubTransport(json)
    let configuration = try PlexServerConfiguration(
        baseURL: #require(URL(string: "https://media.example/plex")), token: "server-token", identity: testIdentity(), machineIdentifier: machineID
    )
    let value = try await call(PlexAPIService(configuration: configuration, transport: transport))
    let requests = await transport.requests
    #expect(requests.allSatisfy { $0.value(forHTTPHeaderField: "X-Plex-Token") == "server-token" })
    return (value, requests.map(requestLine))
}

private let identitySample = #"{"MediaContainer":{"size":0,"claimed":true,"machineIdentifier":"machine","version":"1.40.0.0000"}}"#

private let librarySectionsSample = #"""
{"MediaContainer":{"size":2,"allowSync":false,"title1":"Plex Library","Directory":[
  {"key":"1","type":"movie","title":"Movies","uuid":"section-uuid-1","agent":"tv.plex.agents.movie","thumb":"/:/resources/movie.png"},
  {"key":"2","type":"show","title":"TV Shows","uuid":"section-uuid-2","agent":"tv.plex.agents.series"}]}}
"""#

private let metadataSample = #"""
{"MediaContainer":{"size":1,"librarySectionID":1,"librarySectionTitle":"Movies","Metadata":[
  {"ratingKey":"42","key":"/library/metadata/42","guid":"plex://movie/sample-42","type":"movie","title":"Sample Movie",
   "summary":"A synthetic movie.","year":2024,"contentRating":"PG-13","duration":7200000,"viewOffset":600000,
   "Media":[{"id":1,"container":"mkv","videoCodec":"hevc","audioCodec":"aac","videoResolution":"4k","width":3840,"height":2160,
     "bitrate":20000,"audioChannels":6,"duration":7200000,
     "Part":[{"id":7,"key":"/library/parts/7/1700000000/file.mkv","file":"/data/movies/Sample Movie (2024).mkv","container":"mkv",
       "size":18000000000,"duration":7200000,"exists":true,"accessible":true,
       "Stream":[
         {"id":100,"streamType":1,"codec":"hevc","displayTitle":"4K (HEVC Main 10)"},
         {"id":101,"streamType":2,"codec":"aac","language":"English","languageCode":"eng","displayTitle":"English (AAC 5.1)","selected":true},
         {"id":102,"streamType":3,"key":"/library/streams/102","codec":"srt","language":"English","languageCode":"eng",
          "displayTitle":"English (SRT External)"}]}]}],
   "Genre":[{"id":5,"tag":"Drama"}],"Director":[{"id":6,"tag":"Sample Director"}],"Role":[{"id":8,"tag":"Sample Actor","role":"Lead"}],
   "Marker":[{"type":"intro","startTimeOffset":0,"endTimeOffset":30000}]}]}}
"""#

struct PlexAPISampleTests {
    // MARK: - Account

    @Test func resources() async throws {
        let transport = PlexStubTransport(#"""
        [
          {"name":"Living Room TV","clientIdentifier":"player-1","provides":"player,pubsub-player"},
          {"name":"Home Server","clientIdentifier":"machine","provides":"server","owned":true,"accessToken":"server-token","connections":[
            {"protocol":"https","uri":"https://local.media.example:32400","local":true,"relay":false,"IPv6":false},
            {"protocol":"https","uri":"https://relay.media.example:8443","local":false,"relay":true,"IPv6":false}]}
        ]
        """#)
        let servers = try await PlexAccountService(identity: testIdentity(), transport: transport).servers(accountToken: "account-token")
        let server = try #require(servers.first)
        #expect(servers.count == 1 && server.name == "Home Server" && server.owned == true && server.connections.map(\.relay) == [false, true])
        let request = try #require(await transport.requests.first)
        #expect(requestLine(request) == "GET https://plex.tv/api/v2/resources?includeHttps=1&includeRelay=1&includeIPv6=1")
        #expect(request.value(forHTTPHeaderField: "X-Plex-Token") == "account-token")
    }

    @Test func user() async throws {
        let transport = PlexStubTransport(#"{"id":1001,"uuid":"owner-uuid","username":"owner","title":"Owner","protected":false}"#)
        let user = try await PlexAccountService(identity: testIdentity(), transport: transport).user(accountToken: "account-token")
        #expect(user.id == "1001" && user.uuid == "owner-uuid" && user.title == "Owner" && !user.isProtected)
        let request = try #require(await transport.requests.first)
        #expect(requestLine(request) == "GET https://clients.plex.tv/api/v2/user")
        #expect(request.value(forHTTPHeaderField: "X-Plex-Token") == "account-token")
    }

    @Test func homeUsers() async throws {
        let transport = PlexStubTransport(#"""
        {"id":1,"name":"Sample Home","users":[
          {"id":1001,"uuid":"owner-uuid","title":"Owner","admin":true,"protected":false},
          {"id":1002,"uuid":"kid-uuid","title":"Kid","admin":false,"protected":true}]}
        """#)
        let users = try await PlexAccountService(identity: testIdentity(), transport: transport).homeUsers(accountToken: "account-token")
        #expect(users.map(\.title) == ["Owner", "Kid"] && users.map(\.isProtected) == [false, true])
        let request = try #require(await transport.requests.first)
        #expect(requestLine(request) == "GET https://clients.plex.tv/api/v2/home/users")
        #expect(request.value(forHTTPHeaderField: "X-Plex-Token") == "account-token")
    }

    // MARK: - Discovery and connection

    @Test func identity() async throws {
        let (identifier, requests) = try await stubbed(identitySample, machineID: nil) { try await $0.machineIdentifier() }
        #expect(identifier == "machine" && requests == ["GET /identity"])
    }

    @Test func librarySections() async throws {
        let (libraries, requests) = try await stubbed(librarySectionsSample) { try await $0.libraries() }
        #expect(requests == ["GET /library/sections"])
        #expect(libraries == [
            PlexLibrary(key: "1", title: "Movies", type: "movie", uuid: "section-uuid-1"),
            PlexLibrary(key: "2", title: "TV Shows", type: "show", uuid: "section-uuid-2"),
        ])
    }

    @Test func connectorProbesIdentityThenSections() async throws {
        let transport = PlexRoutingTransport(["/identity": identitySample, "/library/sections": librarySectionsSample])
        let server = try decodeFixture(PlexServerResource.self, #"""
        {"clientIdentifier":"machine","name":"Home Server","provides":"server","accessToken":"server-token",
         "connections":[{"uri":"https://media.example/plex"}]}
        """#)
        let result = try await PlexServerConnector(transport: transport).connect(to: server, identity: testIdentity())
        #expect(result.configuration.machineIdentifier == "machine" && result.libraries.map(\.title) == ["Movies", "TV Shows"])
        #expect(await transport.requests.map(requestLine) == ["GET /identity", "GET /library/sections"])
    }

    // MARK: - Browse

    @Test func libraryItems() async throws {
        let json = #"""
        {"MediaContainer":{"size":2,"totalSize":40,"offset":0,"title1":"Movies","librarySectionID":1,"Metadata":[
          {"ratingKey":"42","key":"/library/metadata/42","guid":"plex://movie/sample-42","type":"movie","title":"Sample Movie","year":2024,
           "duration":7200000,"viewOffset":600000,"addedAt":1700000000,"thumb":"/library/metadata/42/thumb/1700000000"},
          {"ratingKey":"43","key":"/library/metadata/43","type":"movie","title":"Another Movie","year":2023,"viewCount":1}]}}
        """#
        let query = PlexLibraryQuery(type: 1, sort: "titleSort", filters: ["genre": "12"])
        let (page, requests) = try await stubbed(json) { try await $0.items(sectionID: "1", page: PlexPagination(size: 2), query: query) }
        #expect(requests == ["GET /library/sections/1/all?type=1&sort=titleSort&genre=12&X-Plex-Container-Start=0&X-Plex-Container-Size=2"])
        #expect(page.totalSize == 40 && page.librarySectionID == "1" && page.metadata.map(\.title) == ["Sample Movie", "Another Movie"])
        #expect(page.metadata.first?.viewOffset == 600_000 && page.metadata.last?.isWatched == true)
        #expect(try await stubbed(json) { try await $0.items(sectionID: "shared") }.requests == ["GET /library/shared/all"])
    }

    @Test func metadata() async throws {
        let (item, requests) = try await stubbed(metadataSample) { try await $0.metadata(ratingKey: "42") }
        #expect(requests == ["GET /library/metadata/42?includeMarkers=1&includeChapters=1&checkFiles=1&includeStreams=1&includeOnDeck=1"])
        let part = try #require(item.media.first?.parts.first)
        #expect(item.title == "Sample Movie" && item.genres.map(\.tag) == ["Drama"] && item.markers.first?.endTimeOffset == 30000)
        #expect(part.size == 18_000_000_000 && part.isPlayable && part.streams.map(\.streamType) == [1, 2, 3])
        #expect(part.streams.last?.isExternalSubtitle == true)
    }

    @Test func children() async throws {
        let (seasons, requests) = try await stubbed(#"""
        {"MediaContainer":{"size":2,"key":"10","parentTitle":"Sample Show","Metadata":[
          {"ratingKey":"11","key":"/library/metadata/11/children","parentRatingKey":"10","type":"season","title":"Season 1","index":1,
           "parentTitle":"Sample Show","leafCount":8,"viewedLeafCount":8},
          {"ratingKey":"12","key":"/library/metadata/12/children","parentRatingKey":"10","type":"season","title":"Season 2","index":2,
           "parentTitle":"Sample Show","leafCount":8,"viewedLeafCount":3}]}}
        """#) { try await $0.children(ratingKey: "10") }
        #expect(requests == ["GET /library/metadata/10/children?includeStreams=1"])
        #expect(seasons.metadata.map(\.index) == [1, 2] && seasons.metadata.map(\.isWatched) == [true, false])
    }

    @Test func grandchildren() async throws {
        let (episodes, requests) = try await stubbed(#"""
        {"MediaContainer":{"size":1,"totalSize":16,"offset":0,"Metadata":[
          {"ratingKey":"101","key":"/library/metadata/101","parentRatingKey":"11","grandparentRatingKey":"10","type":"episode","title":"Pilot",
           "grandparentTitle":"Sample Show","parentIndex":1,"index":1,"duration":2700000,"viewCount":1}]}}
        """#) { try await $0.grandchildren(ratingKey: "10", page: PlexPagination(size: 1)) }
        #expect(requests == ["GET /library/metadata/10/grandchildren?X-Plex-Container-Start=0&X-Plex-Container-Size=1&includeStreams=1"])
        let episode = try #require(episodes.metadata.first)
        #expect(episodes.totalSize == 16 && episode.grandparentRatingKey == "10" && episode.parentIndex == 1 && episode.index == 1)
    }

    @Test func search() async throws {
        let (results, requests) = try await stubbed(#"""
        {"MediaContainer":{"size":2,"SearchResult":[
          {"score":0.92,"Metadata":{"ratingKey":"42","type":"movie","title":"Sample Movie","year":2024}},
          {"score":0.81,"Metadata":{"ratingKey":"10","type":"show","title":"Sample Show","year":2020}}]}}
        """#) { try await $0.search(query: "sample") }
        #expect(requests == ["GET /library/search?query=sample&searchTypes=movies,tv&includeCollections=1"])
        #expect(results.metadata.map(\.type) == ["movie", "show"])
    }

    @Test func recentlyAdded() async throws {
        let (recent, requests) = try await stubbed(#"""
        {"MediaContainer":{"size":1,"Metadata":[
          {"ratingKey":"101","type":"episode","title":"Pilot","grandparentTitle":"Sample Show",
           "grandparentThumb":"/library/metadata/10/thumb/1700000000","addedAt":1700000000}]}}
        """#) { try await $0.recentlyAdded(page: PlexPagination(size: 20)) }
        #expect(requests == ["GET /library/recentlyAdded?X-Plex-Container-Start=0&X-Plex-Container-Size=20"])
        #expect(recent.metadata.first?.posterPath == "/library/metadata/10/thumb/1700000000")
    }

    @Test func extras() async throws {
        let (extras, requests) = try await stubbed(#"""
        {"MediaContainer":{"size":1,"Metadata":[
          {"ratingKey":"900","key":"/library/metadata/900","type":"clip","subtype":"trailer","title":"Official Trailer","duration":150000}]}}
        """#) { try await $0.extras(ratingKey: "42") }
        #expect(requests == ["GET /library/metadata/42/extras"])
        #expect(extras.metadata.first?.subtype == "trailer")
    }

    @Test func filters() async throws {
        let (filters, requests) = try await stubbed(#"""
        {"MediaContainer":{"size":2,"Directory":[
          {"filter":"genre","filterType":"string","key":"/library/sections/1/genre","title":"Genre","type":"filter"},
          {"filter":"unwatched","filterType":"boolean","key":"/library/sections/1/unwatched","title":"Unplayed","type":"filter"}]}}
        """#) { try await $0.filters(sectionID: "1") }
        #expect(requests == ["GET /library/sections/1/filters"])
        #expect(filters.map(\.filter) == ["genre", "unwatched"] && filters.first?.key == "/library/sections/1/genre")
    }

    @Test func sorts() async throws {
        let (sorts, requests) = try await stubbed(#"""
        {"MediaContainer":{"size":2,"Directory":[
          {"key":"titleSort","descKey":"titleSort:desc","title":"Title","defaultDirection":"asc"},
          {"key":"addedAt","descKey":"addedAt:desc","title":"Date Added","defaultDirection":"desc"}]}}
        """#) { try await $0.sorts(sectionID: "1") }
        #expect(requests == ["GET /library/sections/1/sorts"])
        #expect(sorts.map(\.descKey) == ["titleSort:desc", "addedAt:desc"])
    }

    @Test func firstCharacters() async throws {
        let (characters, requests) = try await stubbed(#"""
        {"MediaContainer":{"size":2,"Directory":[{"key":"A","title":"A","size":3},{"key":"S","title":"S","size":12}]}}
        """#) { try await $0.firstCharacters(sectionID: "1", query: PlexLibraryQuery(type: 1)) }
        #expect(requests == ["GET /library/sections/1/firstCharacter?type=1"])
        #expect(characters.map(\.size) == [3, 12])
    }

    @Test func folders() async throws {
        let (folders, requests) = try await stubbed(#"""
        {"MediaContainer":{"size":1,"title1":"Movies","Directory":[{"key":"/library/sections/1/folder?parent=200","title":"Action"}]}}
        """#) { try await $0.folders(sectionID: "1") }
        #expect(requests == ["GET /library/sections/1/folder?includeCollections=0"])
        #expect(folders.directories.map(\.key) == ["/library/sections/1/folder?parent=200"])
    }

    @Test func personMedia() async throws {
        let (media, requests) = try await stubbed(#"""
        {"MediaContainer":{"size":1,"Metadata":[{"ratingKey":"42","type":"movie","title":"Sample Movie","year":2024}]}}
        """#) { try await $0.personMedia(personID: "8", page: PlexPagination(size: 20)) }
        #expect(requests == ["GET /library/people/8/media?X-Plex-Container-Start=0&X-Plex-Container-Size=20"])
        #expect(media.metadata.map(\.ratingKey) == ["42"])
    }

    @Test func serverKey() async throws {
        let (values, requests) = try await stubbed(#"""
        {"MediaContainer":{"size":2,"Directory":[{"key":"12","title":"Drama"},{"key":"13","title":"Comedy"}]}}
        """#) { try await $0.container(key: "/library/sections/1/genre") }
        #expect(requests == ["GET /library/sections/1/genre"])
        #expect(values.directories.map(\.title) == ["Drama", "Comedy"])
    }

    // MARK: - Hubs

    @Test func homeHubs() async throws {
        let (hubs, requests) = try await stubbed(#"""
        {"MediaContainer":{"size":2,"Hub":[
          {"hubIdentifier":"home.movies.recent","key":"/hubs/home/recentlyAdded?type=1","title":"Recently Added Movies","type":"movie",
           "size":1,"more":true,"Metadata":[{"ratingKey":"42","type":"movie","title":"Sample Movie"}]},
          {"hubIdentifier":"home.television.recent","key":"/hubs/home/recentlyAdded?type=2","title":"Recently Added TV","type":"mixed",
           "size":0,"more":false}]}}
        """#) { try await $0.homeHubs() }
        #expect(requests == ["GET /hubs?count=12&includeGuids=1"])
        #expect(hubs.map(\.id) == ["home.movies.recent"] && hubs.first?.more == true)
    }

    @Test func continueWatching() async throws {
        let (items, requests) = try await stubbed(#"""
        {"MediaContainer":{"size":2,"Hub":[
          {"hubIdentifier":"home.continue","title":"Continue Watching","type":"mixed","Metadata":[
            {"ratingKey":"42","type":"movie","title":"Sample Movie","viewOffset":600000,"duration":7200000}]},
          {"hubIdentifier":"home.ondeck","title":"On Deck","type":"mixed","Metadata":[
            {"ratingKey":"102","type":"episode","title":"Episode 2","grandparentRatingKey":"10","grandparentTitle":"Sample Show"}]}]}}
        """#) { try await $0.continueWatching() }
        #expect(requests == ["GET /hubs?count=20&includeGuids=1&identifier=home.continue,home.ondeck"])
        #expect(items.map(\.ratingKey) == ["42", "102"])
    }

    @Test func sectionHubs() async throws {
        let (hubs, requests) = try await stubbed(#"""
        {"MediaContainer":{"size":1,"Hub":[
          {"hubIdentifier":"movie.recentlyadded.1","key":"/library/sections/1/recentlyAdded","title":"Recently Added in Movies","type":"movie",
           "more":true,"Metadata":[{"ratingKey":"42","type":"movie","title":"Sample Movie"}]}]}}
        """#) { try await $0.sectionHubs(sectionID: "1") }
        #expect(requests == ["GET /hubs/sections/1?count=12&includeGuids=1"])
        #expect(hubs.map(\.key) == ["/library/sections/1/recentlyAdded"])
    }

    @Test func relatedHubs() async throws {
        let (hubs, requests) = try await stubbed(#"""
        {"MediaContainer":{"size":1,"Hub":[
          {"hubIdentifier":"movie.similar","key":"/library/metadata/42/similar","title":"More Like This","type":"movie",
           "Metadata":[{"ratingKey":"43","type":"movie","title":"Another Movie"}]}]}}
        """#) { try await $0.relatedHubs(ratingKey: "42") }
        #expect(requests == ["GET /hubs/metadata/42/related?count=10"])
        #expect(hubs.first?.metadata.map(\.title) == ["Another Movie"])
    }

    // MARK: - Downloads

    @Test func downloadPlan() async throws {
        let (plan, requests) = try await stubbed(metadataSample) { try await $0.downloadPlan(ratingKey: "42") }
        #expect(requests == ["GET /library/metadata/42?includeMarkers=1&includeChapters=1&checkFiles=1&includeStreams=1&includeOnDeck=1"])
        let part = try #require(plan.parts.first)
        #expect(plan.mediaIndex == 0 && requestLine(part.request) == "GET /library/parts/7/1700000000/file.mkv")
        #expect(part.subtitles.map { requestLine($0.request) } == ["GET /library/streams/102.srt?encoding=utf-8"])
    }
}
