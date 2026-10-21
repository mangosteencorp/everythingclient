import Foundation
import Plex_Shared_Backend
@testable import PlexIntegration
import Testing

struct PlexLibraryServiceTests {
    /// A show and a remake share the title; the second movie hit is the 2021 film, part watched.
    static let search = #"""
    {"MediaContainer": {"size": 4, "SearchResult": [
        {"score": 0.95, "Metadata": {"ratingKey": "10", "type": "show", "title": "Dune", "year": 2021}},
        {"score": 0.9, "Metadata": {"ratingKey": "41", "type": "movie", "title": "Dune", "year": 1984, "duration": 8220000}},
        {"score": 0.85, "Metadata": {"ratingKey": "42", "type": "movie", "title": "DUNE", "year": 2021, "duration": 9315000, "viewOffset": 3260000}},
        {"score": 0.8, "Metadata": {"ratingKey": "43", "type": "movie", "title": "Dune: Part Two", "year": 2024, "duration": 9960000, "viewCount": 1}}
    ]}}
    """#

    @Test func findsTheMovieWithTheSameTitleAndYear() async throws {
        let transport = RecordingTransport(["/library/search": Self.search])
        let launcher = try LaunchingFake(best: connection(transport: transport))
        _ = try await launcher.connectBest()
        let service = PlexLibraryService(launcher: launcher)

        let match = try #require(try await service.findMovie(title: "  Dune ", year: 2021))

        #expect(match == PlexMovieMatch(id: "42", title: "DUNE", runtimeSeconds: 9315, playedFraction: 3260.0 / 9315, resumeSeconds: 3260, isPlayed: false))
        #expect(match.api != nil)
        let request = try #require(await transport.requests.first)
        #expect(request.url?.path == "/library/search")
        #expect(query(request)["query"] == "Dune")
        // The live connection is used as is.
        #expect(await launcher.resumeCount == 0)
    }

    @Test func toleratesAYearApartPunctuationAndCase() async throws {
        let service = try await connectedService(RecordingTransport(["/library/search": Self.search]))
        let match = try await service.findMovie(title: "dune - part two", year: 2023)
        #expect(match?.id == "43")
        #expect(match?.isPlayed == true)
    }

    @Test func withoutAYearTakesTheFirstMovieWithThatTitle() async throws {
        let service = try await connectedService(RecordingTransport(["/library/search": Self.search]))
        #expect(try await service.findMovie(title: "Dune", year: nil)?.id == "41")
    }

    @Test func anotherYearOrAShowIsNotInTheLibrary() async throws {
        let service = try await connectedService(RecordingTransport(["/library/search": Self.search]))
        #expect(try await service.findMovie(title: "Dune", year: 2000) == nil)
    }

    @Test func signedOutIsNotConnectedWithoutRestoringAnything() async throws {
        let launcher = LaunchingFake()
        let service = PlexLibraryService(launcher: launcher)
        #expect(await service.isSignedIn == false)
        await #expect(throws: PlexLibraryError.notConnected) { try await service.findMovie(title: "Dune", year: 2021) }
        #expect(await launcher.resumeCount == 0)
    }

    @Test func aSavedAccountIsRestoredBeforeSearching() async throws {
        let transport = RecordingTransport(["/library/search": Self.search])
        let launcher = try LaunchingFake(hasAccount: true, resume: .success(connection(transport: transport)))
        let service = PlexLibraryService(launcher: launcher)
        #expect(await service.isSignedIn)
        #expect(try await service.findMovie(title: "Dune", year: 2021)?.id == "42")
        #expect(await launcher.resumeCount == 1)
    }

    @Test func aServerFailureIsReadable() async throws {
        let service = try await connectedService(RecordingTransport([:]))
        await #expect(throws: PlexLibraryError.failed(L10n.plexErrorGeneric)) { try await service.findMovie(title: "Dune", year: 2021) }
    }

    @Test func thePlayerURLCarriesTheTokenButNoOtherPlexHeader() throws {
        let request = try connection().api.streamRequest(PlexStreamOptions(ratingKey: "42", session: "s1"))
        #expect(request.value(forHTTPHeaderField: "X-Plex-Client-Identifier") == "tests")

        let url = try #require(PlexAVPlayerFactory.playbackURL(for: request))

        #expect(url.absoluteString == "\(try #require(request.url?.absoluteString))&X-Plex-Token=token")
        #expect(!url.absoluteString.contains("X-Plex-Client-Identifier"))
        #expect(!url.absoluteString.contains("X-Plex-Product"))
    }

    @Test func thePlayerURLEncodesTheTokenOnAURLWithoutAQuery() throws {
        let identity = try PlexClientIdentity(identifier: "tests", product: "Tests", version: "1", platform: "iOS")
        let configuration = try PlexServerConfiguration(baseURL: #require(URL(string: "https://plex.example")), token: "a+b/c", identity: identity)
        let part = PlexMediaPart(id: "7", key: "/library/parts/7/file.mp4")
        let request = try PlexAPIService(configuration: configuration).directPlayRequest(part: part)

        #expect(PlexAVPlayerFactory.playbackURL(for: request)?.absoluteString == "https://plex.example/library/parts/7/file.mp4?X-Plex-Token=a%2Bb%2Fc")
    }

    private func connectedService(_ transport: RecordingTransport) async throws -> PlexLibraryService {
        try PlexLibraryService(launcher: LaunchingFake(hasAccount: true, resume: .success(connection(transport: transport))))
    }
}

/// Answers by URL path, `{"MediaContainer":{}}` for anything else, and records every request. With no routes at all
/// it fails every request, as a server error would.
actor RecordingTransport: PlexHTTPTransport {
    private(set) var requests: [URLRequest] = []
    private let routes: [String: String]

    init(_ routes: [String: String]) { self.routes = routes }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request)
        let url = try #require(request.url)
        let response = try #require(HTTPURLResponse(url: url, statusCode: routes.isEmpty ? 500 : 200, httpVersion: nil, headerFields: nil))
        return (Data((routes[url.path] ?? #"{"MediaContainer":{}}"#).utf8), response)
    }
}

func query(_ request: URLRequest?) -> [String: String] {
    guard let url = request?.url, let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems else { return [:] }
    return Dictionary(items.map { ($0.name, $0.value ?? "") }, uniquingKeysWith: { $1 })
}
