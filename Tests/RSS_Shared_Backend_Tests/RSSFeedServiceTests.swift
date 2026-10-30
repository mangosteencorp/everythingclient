import Foundation
@testable import RSS_Shared_Backend
import Testing

struct RSSFeedServiceTests {
    private let url = PodcastFeed.ignMovieReviews

    @Test func fetchesAndParsesTheFeed() async throws {
        let transport = try RSSStubTransport(ignFixtureData())
        let feed = try await RSSFeedService(transport: transport).feed(at: url)
        #expect(feed.title == "IGN Movie Reviews")
        #expect(feed.episodes.count == 6)
        #expect(await transport.requests.map(\.url) == [url])
    }

    @Test func reusesTheFeedWithinItsTimeToLive() async throws {
        let transport = try RSSStubTransport(ignFixtureData())
        let service = RSSFeedService(transport: transport, timeToLive: .seconds(3600))
        let first = try await service.feed(at: url)
        let second = try await service.feed(at: url)
        #expect(first == second)
        #expect(await transport.requests.count == 1)
    }

    @Test func downloadsAgainOnceExpired() async throws {
        let transport = try RSSStubTransport(ignFixtureData())
        let service = RSSFeedService(transport: transport, timeToLive: .zero)
        _ = try await service.feed(at: url)
        _ = try await service.feed(at: url)
        #expect(await transport.requests.count == 2)
    }

    @Test func throwsOnNon2xxAndDoesNotKeepTheFailure() async throws {
        let transport = RSSStubTransport(Data("Not found".utf8), status: 404)
        let service = RSSFeedService(transport: transport, timeToLive: .seconds(3600))
        await #expect(throws: RSSFeedError.httpStatus(404)) { try await service.feed(at: url) }
        await #expect(throws: RSSFeedError.httpStatus(404)) { try await service.feed(at: url) }
        #expect(await transport.requests.count == 2)
    }

    @Test func throwsOnNonHTTPResponse() async {
        let service = RSSFeedService(transport: RSSStubTransport(Data(), nonHTTP: true))
        await #expect(throws: RSSFeedError.nonHTTPResponse) { try await service.feed(at: url) }
    }

    @Test func throwsParserErrorForABodyThatIsNotRSS() async {
        let service = RSSFeedService(transport: RSSStubTransport(Data("<html><body>Hi</body></html>".utf8)))
        await #expect(throws: RSSParserError.missingChannel) { try await service.feed(at: url) }
    }
}
