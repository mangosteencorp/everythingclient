import AVFoundation
import Foundation
import Plex_Shared_Backend
@testable import PlexIntegration
import Testing

@MainActor
struct PlexMoviePlayerModelTests {
    @Test func transcodesAFileAVPlayerCannotOpenAndEndsTheSessionOnStop() async throws {
        let transport = RecordingTransport(["/library/metadata/42": metadata(container: "mkv", codec: "hevc")])
        let factory = RecordingPlayerFactory()
        let model = try PlexMoviePlayerModel(match: match(transport), factory: factory)

        await model.start()
        let request = try #require(factory.requests.first)
        #expect(request.url?.path == "/video/:/transcode/universal/start.m3u8")
        #expect(model.player != nil)

        await model.stop()?.value

        #expect(model.player == nil)
        let session = try #require(query(request)["session"])
        let sent = await transport.requests
        #expect(sent.contains { $0.url?.path == "/:/timeline" && query($0)["state"] == "stopped" && query($0)["duration"] == "9315000" })
        #expect(sent.contains { $0.url?.path == "/video/:/transcode/universal/stop" && query($0)["session"] == session })
    }

    @Test func directPlaysAnMP4AndOnlyReportsTheStop() async throws {
        let transport = RecordingTransport(["/library/metadata/42": metadata(container: "mp4", codec: "h264")])
        let factory = RecordingPlayerFactory()
        let model = try PlexMoviePlayerModel(match: match(transport), factory: factory)

        await model.start()
        #expect(factory.requests.first?.url?.path == "/library/parts/7/file")
        await model.stop()?.value

        let sent = await transport.requests
        #expect(sent.contains { $0.url?.path == "/:/timeline" && query($0)["state"] == "stopped" })
        #expect(!sent.contains { $0.url?.path == "/video/:/transcode/universal/stop" })
        #expect(model.stop() == nil)
    }

    @Test func aMatchWithoutAServerExplainsInsteadOfPlaying() async {
        let factory = RecordingPlayerFactory()
        let model = PlexMoviePlayerModel(
            match: PlexMovieMatch(id: "42", title: "Dune", runtimeSeconds: nil, playedFraction: 0, resumeSeconds: 0, isPlayed: false),
            factory: factory
        )

        await model.start()

        #expect(model.error == L10n.plexLibraryNotConnected)
        #expect(factory.requests.isEmpty)
    }

    private func match(_ transport: RecordingTransport) throws -> PlexMovieMatch {
        try PlexMovieMatch(PlexMetadata(ratingKey: "42", title: "Dune", type: "movie"), api: connection(transport: transport).api)
    }

    private func metadata(container: String, codec: String) -> String {
        #"""
        {"MediaContainer": {"size": 1, "Metadata": [{"ratingKey": "42", "type": "movie", "title": "Dune", "duration": 9315000,
            "Media": [{"id": 1, "container": "\#(container)", "videoCodec": "\#(codec)",
                "Part": [{"id": 7, "key": "/library/parts/7/file", "container": "\#(container)"}]}]}]}}
        """#
    }
}

@MainActor
final class RecordingPlayerFactory: PlexPlayerCreating {
    private(set) var requests: [URLRequest] = []

    func player(for request: URLRequest) -> AVPlayer {
        requests.append(request)
        return AVPlayer()
    }
}
