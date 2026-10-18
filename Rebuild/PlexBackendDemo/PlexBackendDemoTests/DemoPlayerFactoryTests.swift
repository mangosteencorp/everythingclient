import Foundation
import Plex_Shared_Backend
@testable import PlexBackendDemo
import Testing

@MainActor
struct DemoPlayerFactoryTests {
    @Test func directPlayURLCarriesOnlyTheToken() async throws {
        let session = makeSession()
        session.loadSamples()
        let api = try #require(session.api)
        let part = try #require(try await api.metadata(ratingKey: "100").media.first?.parts.first)
        let request = try api.directPlayRequest(part: part)
        let url = try #require(DemoPlayerFactory.playbackURL(for: request))
        #expect(request.url?.query == nil && url.path == request.url?.path)
        #expect(url.query == "X-Plex-Token=sample")
    }

    @Test func transcodeURLKeepsItsOwnParametersAndEscapes() throws {
        let session = makeSession()
        session.loadSamples()
        let api = try #require(session.api)
        let request = try api.streamRequest(PlexStreamOptions(ratingKey: "100", session: "s"))
        let original = try #require(request.url?.absoluteString)
        #expect(DemoPlayerFactory.playbackURL(for: request)?.absoluteString == original + "&X-Plex-Token=sample")
    }

    @Test func localFilesAreUnchanged() {
        let file = URL(filePath: "/tmp/movie.mp4")
        #expect(DemoPlayerFactory.playbackURL(for: URLRequest(url: file)) == file)
    }
}
