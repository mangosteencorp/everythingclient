import Podcast_Player
import RSS_Shared_Backend
@testable import TMDB_MovieDetail
import XCTest

@MainActor
final class MoviePodcastReviewViewModelTests: XCTestCase {
    func testLoadFindsTheExactReviewInTheIGNFeed() async {
        let provider = StubRSSFeedProvider()
        let viewModel = makeViewModel(provider)

        await viewModel.load(title: "  Superman  ", releaseDate: nil)

        XCTAssertEqual(provider.requestedURLs, [PodcastFeed.ignMovieReviews])
        XCTAssertEqual(viewModel.state.episode?.title, "Superman Review")
        XCTAssertTrue(viewModel.isVisible)
    }

    func testLoadHidesTheSectionWhenTheShowNeverReviewedTheMovie() async {
        let viewModel = makeViewModel(StubRSSFeedProvider())

        await viewModel.load(title: "Dune", releaseDate: nil)

        XCTAssertEqual(viewModel.state, .notFound)
        XCTAssertFalse(viewModel.isVisible)
    }

    func testLoadPicksTheReviewPublishedClosestToTheReleaseDate() async {
        let remake = Date(timeIntervalSince1970: 1_701_000_000) // November 2023
        let original = Date(timeIntervalSince1970: 1_634_000_000) // October 2021
        let provider = StubRSSFeedProvider(result: .success(RSSFeed(title: "IGN Movie Reviews", items: [
            .stub(title: "Silent Night Review", guid: "2023", publishedAt: remake),
            .stub(title: "Silent Night Review", guid: "2021", publishedAt: original),
        ])))
        let viewModel = makeViewModel(provider)

        await viewModel.load(title: "Silent Night", releaseDate: original)

        XCTAssertEqual(viewModel.state.episode?.id, "2021")
    }

    func testLoadSurfacesAFailureAndReloadRetriesIt() async {
        let provider = StubRSSFeedProvider(result: .failure(StubError()))
        let viewModel = makeViewModel(provider)

        await viewModel.load(title: "Superman", releaseDate: nil)
        XCTAssertEqual(viewModel.state, .error("stub failure"))
        XCTAssertTrue(viewModel.isVisible)

        provider.result = .success(.stub())
        await viewModel.reload()

        XCTAssertEqual(viewModel.state.episode?.title, "Superman Review")
        XCTAssertEqual(provider.requestedURLs.count, 2)
    }

    func testLoadSkipsARepeatOfTheSameTitle() async {
        let provider = StubRSSFeedProvider()
        let viewModel = makeViewModel(provider)

        await viewModel.load(title: "Superman", releaseDate: nil)
        await viewModel.load(title: "Superman", releaseDate: nil)

        XCTAssertEqual(provider.requestedURLs.count, 1)
    }

    func testLoadSearchesAgainWhenTheTitleChanges() async {
        let provider = StubRSSFeedProvider()
        let viewModel = makeViewModel(provider)

        await viewModel.load(title: "Superman", releaseDate: nil)
        await viewModel.load(title: "Clayface", releaseDate: nil)

        XCTAssertEqual(provider.requestedURLs.count, 2)
        XCTAssertEqual(viewModel.state.episode?.title, "Clayface Review")
    }

    func testLoadIgnoresBlankTitles() async {
        let provider = StubRSSFeedProvider()
        let viewModel = makeViewModel(provider)

        await viewModel.load(title: "   ", releaseDate: nil)

        XCTAssertTrue(provider.requestedURLs.isEmpty)
        XCTAssertEqual(viewModel.state, .loading)
    }

    func testCancelledLoadForgetsTheTitleSoReEnteringSearchesAgain() async {
        let provider = StubRSSFeedProvider()
        let viewModel = makeViewModel(provider)

        let leftPage = Task { await viewModel.load(title: "Superman", releaseDate: nil) }
        leftPage.cancel()
        await leftPage.value
        XCTAssertEqual(viewModel.state, .loading)

        await viewModel.load(title: "Superman", releaseDate: nil)

        XCTAssertEqual(provider.requestedURLs.count, 2)
        XCTAssertEqual(viewModel.state.episode?.title, "Superman Review")
    }

    /// A silent player, so no test creates an `AVPlayer`.
    private func makeViewModel(_ provider: StubRSSFeedProvider) -> MoviePodcastReviewViewModel {
        MoviePodcastReviewViewModel(feedProvider: provider, player: PodcastPlayer(engine: PodcastSilentAudioEngine()))
    }
}

private extension MoviePodcastReviewState {
    var episode: PodcastEpisode? { if case let .found(episode) = self { return episode }; return nil }
}
