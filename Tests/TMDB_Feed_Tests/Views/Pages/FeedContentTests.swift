import CoreFeatures
import SwiftUI
@testable import TMDB_Feed
import TMDB_Shared_UI
import ViewInspector
import XCTest

@available(iOS 16.0, *)
@MainActor
final class FeedContentTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // These assertions inspect a `List`, so pin the feed layout instead of inheriting
        // whatever the last shuffle persisted.
        DesignCoordinator.shared.select(FeedContentDesign.list)
    }

    private func movieContent(_ viewModel: MovieFeedViewModel) -> MovieFeedContent<Int> {
        MovieFeedContent(viewModel: viewModel, detailRouteBuilder: { _ in 1 })
    }

    func testLoadingStateShowsProgress() throws {
        // `load` marks the feed as loading synchronously before the request starts.
        let viewModel = MovieFeedViewModel(feedType: .nowPlaying, apiService: MockAPIService())
        viewModel.load()

        XCTAssertNoThrow(try movieContent(viewModel).inspect().find(ViewType.ProgressView.self))
    }

    func testMovieListDisplay() async throws {
        let service = MockAPIService()
        service.mockNowPlayingResult = .success(MovieListResponse(
            dates: nil, page: 1, results: [sampleApeMovie], totalPages: 1, totalResults: 1
        ))
        let viewModel = MovieFeedViewModel(feedType: .nowPlaying, apiService: service)
        viewModel.load()
        await waitUntil { !viewModel.movies.isEmpty }

        let list = try movieContent(viewModel).inspect().find(ViewType.List.self)
        XCTAssertNoThrow(try list.find(FeedItemRow<Int>.self))
    }

    func testAppearingLoadsTheFeed() throws {
        let viewModel = TVShowFeedViewModel(feedType: .onTheAir, apiService: MockAPIService())
        let content = TVShowFeedContent(viewModel: viewModel, detailRouteBuilder: { _ in 1 })

        try content.body.inspect().callOnAppear()
        XCTAssertTrue(viewModel.isLoading)
    }

    func testFeedKindsExist() {
        XCTAssertEqual(FeedKind.allCases.count, 6)
        XCTAssertEqual(FeedKind.allCases.filter { $0.movieFeedType != nil }.count, 4)
        XCTAssertEqual(FeedKind.allCases.filter { $0.tvShowFeedType != nil }.count, 2)
    }
}
