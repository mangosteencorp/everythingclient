import Foundation
@testable import Plex_Shared_Backend
import Testing

struct PlexLibraryTests {
    @Test func decodesMixedScalarAndSingletonRepresentations() throws {
        let response = try decodeFixture(PlexResponse.self, #"""
        {"MediaContainer":{"size":"1","totalSize":9,"offset":"2","Directory":{"key":7,"title":"Movies","type":"movie"},
        "Metadata":{"ratingKey":42,"title":"Movie","type":"movie","year":"2026","duration":"9000000","viewOffset":12,
          "parentRatingKey":8,"grandparentRatingKey":"9","Media":{"id":1,"videoResolution":1080,"width":"1920",
            "Part":{"id":2,"key":"/parts/2/file.mkv","size":"5000000000","exists":"1","accessible":true,
              "Stream":{"id":3,"streamType":"3","key":"/subs/3","codec":"srt","forced":"false","selected":1}}}}}}
        """#)
        let container = response.mediaContainer
        #expect(container.size == 1 && container.totalSize == 9 && container.offset == 2)
        #expect(container.libraries.first?.key == "7")
        let item = try #require(container.metadata.first)
        #expect(item.ratingKey == "42" && item.year == 2026 && item.duration == 9_000_000)
        #expect(item.parentRatingKey == "8")
        let version = try #require(item.media.first)
        #expect(version.videoResolution == "1080" && version.width == 1920)
        let part = try #require(version.parts.first)
        #expect(part.size == 5_000_000_000 && part.isPlayable)
        #expect(part.streams.first?.isExternalSubtitle == true)
        #expect(part.streams.first?.forced == false && part.streams.first?.selected == true)
    }

    @Test func absentAndNullCollectionsDecodeAsEmpty() throws {
        let response = try decodeFixture(PlexResponse.self, #"{"MediaContainer":{"Metadata":null}}"#)
        #expect(response.mediaContainer.metadata.isEmpty && response.mediaContainer.libraries.isEmpty)
    }

    @Test func malformedAvailabilityDoesNotBecomePlayable() {
        #expect(throws: DecodingError.self) { try decodeFixture(PlexMediaPart.self, #"{"exists":"maybe"}"#) }
        #expect(throws: DecodingError.self) { try decodeFixture(PlexResponse.self, #"{"MediaContainer":{"Metadata":[{"title":"Missing ID","type":"movie"}]}}"#) }
    }

    @Test func serviceReturnsLibrariesAndPagedItems() async throws {
        let transport = PlexStubTransport(#"""
        {"MediaContainer":{"totalSize":"12","offset":10,
          "Directory":[{"key":"1","title":"Movies","type":"movie"}],
          "Metadata":[{"ratingKey":"42","title":"Movie","type":"movie"}]}}
        """#)
        let service = PlexAPIService(configuration: try testConfiguration(), transport: transport)
        #expect(try await service.libraries().first?.title == "Movies")
        let page = try await service.items(sectionID: "1", page: PlexPagination(start: 10, size: 2))
        #expect(page.totalSize == 12 && page.offset == 10 && page.metadata.count == 1)
        #expect(try await service.children(ratingKey: "42").metadata.count == 1)
        #expect(try await service.grandchildren(ratingKey: "42").metadata.count == 1)
    }

    @Test func serviceFindsRequestedMetadataAndBuildsAllParts() async throws {
        let transport = PlexStubTransport(#"""
        {"MediaContainer":{"Metadata":[
          {"ratingKey":"other","title":"Other","type":"movie"},
          {"ratingKey":"42","title":"Movie","type":"movie","Media":[{"Part":[{"key":"/parts/1.mkv"},{"key":"/parts/2.mkv"}]}]}
        ]}}
        """#)
        let service = PlexAPIService(configuration: try testConfiguration(), transport: transport)
        #expect(try await service.metadata(ratingKey: "42").title == "Movie")
        #expect(try await service.downloadPlan(ratingKey: "42").parts.count == 2)
        await #expect(throws: PlexAPIError.metadataNotFound) { try await service.metadata(ratingKey: "missing") }
    }

    @Test(arguments: [301, 401, 403, 404, 429, 500])
    func reportsHTTPFailuresWithoutResponseBody(status: Int) async throws {
        let service = PlexAPIService(configuration: try testConfiguration(), transport: PlexStubTransport("sensitive body", status: status))
        await #expect(throws: PlexAPIError.httpStatus(status)) { try await service.libraries() }
    }

    @Test func rejectsNonHTTPAndMalformedJSONResponses() async throws {
        let configuration = try testConfiguration()
        let nonHTTP = PlexAPIService(configuration: configuration, transport: PlexStubTransport("{}", nonHTTP: true))
        await #expect(throws: PlexAPIError.nonHTTPResponse) { try await nonHTTP.libraries() }
        let malformed = PlexAPIService(configuration: configuration, transport: PlexStubTransport("invalid"))
        await #expect(throws: DecodingError.self) { try await malformed.libraries() }
    }

    @Test func canceledTaskDoesNotStartNetworkRequest() async throws {
        let transport = PlexStubTransport(#"{"MediaContainer":{}}"#)
        let service = PlexAPIService(configuration: try testConfiguration(), transport: transport)
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await service.libraries()
        }
        await #expect(throws: CancellationError.self) { try await task.value }
        #expect(await transport.requests.isEmpty)
    }
}
