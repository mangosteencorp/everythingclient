import Foundation
@testable import Plex_Shared_Backend
import Testing

struct PlexDownloadTests {
    private func item(_ versions: [PlexMediaVersion]) -> PlexMetadata {
        PlexMetadata(ratingKey: "42", title: "Movie", type: "movie", media: versions)
    }

    @Test func preservesAllPartsByDefaultAndSupportsPlezySelection() throws {
        let metadata = item([PlexMediaVersion(parts: [PlexMediaPart(key: "/parts/1.mkv"), PlexMediaPart(key: "/parts/2.mkv")])])
        let planner = PlexDownloadPlanner(configuration: try testConfiguration())
        let plan = try planner.plan(for: metadata)
        #expect(plan.ratingKey == "42" && plan.mediaIndex == 0)
        #expect(plan.parts.map(\.partIndex) == [0, 1])
        #expect(plan.parts.map { $0.request.url?.path } == ["/plex/parts/1.mkv", "/plex/parts/2.mkv"])
        #expect(plan.parts.allSatisfy { $0.request.value(forHTTPHeaderField: "X-Plex-Token") == "server-token" })
        #expect(try planner.plan(for: metadata, selection: .firstPlayable).parts.count == 1)
    }

    @Test func unavailablePartFailsCompletePlan() throws {
        let metadata = item([PlexMediaVersion(parts: [PlexMediaPart(key: "/parts/1"), PlexMediaPart(id: "2", key: "/parts/2", exists: false)])])
        let planner = PlexDownloadPlanner(configuration: try testConfiguration())
        #expect(throws: PlexAPIError.unavailablePart("2")) { try planner.plan(for: metadata) }
        #expect(try planner.plan(for: metadata, selection: .firstPlayable).parts.first?.partIndex == 0)
    }

    @Test func firstPlayableSkipsUnavailableParts() throws {
        let metadata = item([PlexMediaVersion(parts: [PlexMediaPart(key: "/parts/1", accessible: false), PlexMediaPart(key: "/parts/2")])])
        let plan = try PlexDownloadPlanner(configuration: testConfiguration()).plan(for: metadata, selection: .firstPlayable)
        #expect(plan.parts.first?.partIndex == 1)
    }

    @Test(arguments: [-1, 0, 99])
    func fallsBackFromInvalidOrUnavailableVersion(index: Int) throws {
        let metadata = item([
            PlexMediaVersion(parts: [PlexMediaPart(key: "/parts/1", exists: false)]),
            PlexMediaVersion(parts: [PlexMediaPart(key: "/parts/2")]),
        ])
        let plan = try PlexDownloadPlanner(configuration: testConfiguration()).plan(for: metadata, mediaIndex: index)
        #expect(plan.mediaIndex == 1)
    }

    @Test func honorsRequestedAvailableVersion() throws {
        let metadata = item([PlexMediaVersion(parts: [PlexMediaPart(key: "/parts/1")]), PlexMediaVersion(parts: [PlexMediaPart(key: "/parts/2")])])
        let plan = try PlexDownloadPlanner(configuration: testConfiguration()).plan(for: metadata, mediaIndex: 1)
        #expect(plan.mediaIndex == 1 && plan.parts.first?.request.url?.path == "/plex/parts/2")
    }

    @Test func rejectsMissingOrUnavailableMedia() throws {
        let planner = PlexDownloadPlanner(configuration: try testConfiguration())
        let fixtures = [
            item([]), item([PlexMediaVersion()]), item([PlexMediaVersion(parts: [PlexMediaPart()])]),
            item([PlexMediaVersion(parts: [PlexMediaPart(key: "/part", accessible: false)])]),
        ]
        for metadata in fixtures {
            #expect(throws: PlexAPIError.noDownloadableMedia) { try planner.plan(for: metadata) }
        }
    }

    @Test(arguments: [
        ("subrip", "srt"), ("mov_text", "srt"), ("SSA", "ass"), ("ass", "ass"), ("webvtt", "vtt"),
        ("pgs", "sup"), ("hdmv_pgs_subtitle", "sup"), ("dvd_subtitle", "sub"), ("unknown", "srt"),
    ])
    func plansOnlyExternalSubtitles(codec: String, extensionName: String) throws {
        let streams = [
            PlexMediaStream(id: "s", streamType: 3, key: "/subs/a%20b?signature=a%2Bb", codec: codec),
            PlexMediaStream(streamType: 3, codec: "srt"),
            PlexMediaStream(streamType: 2, key: "/audio/1", codec: "aac"),
        ]
        let metadata = item([PlexMediaVersion(parts: [PlexMediaPart(key: "/parts/1", streams: streams)])])
        let plan = try PlexDownloadPlanner(configuration: testConfiguration()).plan(for: metadata)
        let subtitles = try #require(plan.parts.first?.subtitles)
        #expect(subtitles.count == 1)
        let subtitle = try #require(subtitles.first)
        #expect(subtitle.fileExtension == extensionName)
        #expect(subtitle.request.url?.absoluteString == "https://media.example/plex/subs/a%20b.\(extensionName)?signature=a%2Bb&encoding=utf-8")
        #expect(subtitle.request.value(forHTTPHeaderField: "Accept") == "*/*")
    }

    @Test func refusesExternalMediaAndSubtitleOrigins() throws {
        let planner = PlexDownloadPlanner(configuration: try testConfiguration())
        let media = item([PlexMediaVersion(parts: [PlexMediaPart(key: "https://other.example/movie")])])
        #expect(throws: PlexAPIError.invalidPath) { try planner.plan(for: media) }
        let subtitle = PlexMediaStream(streamType: 3, key: "https://other.example/sub", codec: "srt")
        let metadata = item([PlexMediaVersion(parts: [PlexMediaPart(key: "/parts/1", streams: [subtitle])])])
        #expect(throws: PlexAPIError.invalidPath) { try planner.plan(for: metadata) }
    }
}
