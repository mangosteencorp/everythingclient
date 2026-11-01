import Foundation
@testable import PodcastDemo
import RSS_Shared_Backend
import Testing

/// Returns `result` for every request and records the URLs asked for.
final class StubFeedProvider: RSSFeedProviding, @unchecked Sendable {
    var result: Result<RSSFeed, any Error>
    private(set) var requestedURLs: [URL] = []

    init(_ result: Result<RSSFeed, any Error>) {
        self.result = result
    }

    func feed(at url: URL) async throws -> RSSFeed {
        requestedURLs.append(url)
        return try result.get()
    }
}

struct StubError: LocalizedError {
    var errorDescription: String? { "stub failure" }
}

/// IGN-style titles; the TV show comes first, so only an exact match finds the movie.
private func reviewFeed(_ titles: [String] = [
    "Clayface Review", "Superman & Lois Season 4 Review", "Superman Review", "My Adventures With Superman Review",
]) -> RSSFeed {
    RSSFeed(title: "IGN Movie Reviews", items: titles.map {
        RSSItem(guid: $0, title: $0, enclosure: RSSEnclosure(url: URL(fileURLWithPath: "/\($0).mp3")))
    })
}

@MainActor
struct PodcastReviewsModelTests {
    @Test func loadsTheIGNFeedsEpisodes() async {
        let provider = StubFeedProvider(.success(reviewFeed()))
        let model = PodcastReviewsModel(feedProvider: provider)
        #expect(model.state == .loading)

        await model.load()

        #expect(model.state == .loaded(reviewFeed().episodes))
        #expect(provider.requestedURLs == [PodcastFeed.ignMovieReviews])
    }

    @Test func reportsAFailure() async {
        let model = PodcastReviewsModel(feedProvider: StubFeedProvider(.failure(StubError())))

        await model.load()

        #expect(model.state == .failed("stub failure"))
    }

    @Test func retryRecoversFromAFailure() async {
        let provider = StubFeedProvider(.failure(StubError()))
        let model = PodcastReviewsModel(feedProvider: provider)
        await model.load()

        provider.result = .success(reviewFeed())
        await model.retry()

        #expect(model.state == .loaded(reviewFeed().episodes))
        #expect(provider.requestedURLs.count == 2)
    }

    @Test func emptySearchListsEveryEpisodeWithoutAMatch() async {
        let model = await loadedModel()

        #expect(model.matchedReview == nil)
        #expect(model.filteredEpisodes.map(\.title) == reviewFeed().episodes.map(\.title))
    }

    @Test func searchFiltersByTitle() async {
        let model = await loadedModel()

        model.searchText = "lois"

        #expect(model.filteredEpisodes.map(\.title) == ["Superman & Lois Season 4 Review"])
        #expect(model.matchedReview == nil)
    }

    @Test func exactMovieTitleShowsItsReviewOnTop() async {
        let model = await loadedModel()

        model.searchText = "superman"

        #expect(model.matchedReview?.title == "Superman Review")
        #expect(model.filteredEpisodes.map(\.title) == [
            "Superman & Lois Season 4 Review", "My Adventures With Superman Review",
        ])
    }

    @Test func supermanDoesNotMatchSupermanAndLois() async {
        let model = await loadedModel(reviewFeed(["Superman & Lois Season 4 Review"]))

        model.searchText = "Superman"

        #expect(model.matchedReview == nil)
        #expect(model.filteredEpisodes.map(\.title) == ["Superman & Lois Season 4 Review"])
    }

    @Test func fixtureModeServesTheBundledFeed() async throws {
        let episodes = try await FixtureRSSFeedProvider().feed(at: PodcastFeed.ignMovieReviews).episodes

        #expect(episodes.count == 6)
        #expect(episodes.contains { $0.title == "Superman Review" })
    }

    private func loadedModel(_ feed: RSSFeed = reviewFeed()) async -> PodcastReviewsModel {
        let model = PodcastReviewsModel(feedProvider: StubFeedProvider(.success(feed)))
        await model.load()
        return model
    }
}
