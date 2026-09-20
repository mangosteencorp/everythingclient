import SwiftUI
@testable import TMDB_Feed
import ViewInspector
import XCTest

final class FeedLazyLoadingTests: XCTestCase {
    @MainActor
    func testOpeningPageDoesNotPreloadTVFeeds() throws {
        let service = MockAPIService()
        let movies = MovieFeedViewModel(apiService: service)
        let shows = TVShowFeedViewModel(apiService: service)
        let page = MovieFeedListPage(
            movieViewModel: movies,
            tvShowViewModel: shows,
            detailRouteBuilder: { _ in 1 },
            tvShowDetailRouteBuilder: { _ in 1 }
        )
        try page.body.inspect().callOnAppear()

        XCTAssertTrue(movies.isLoading(for: .nowPlaying))
        XCTAssertFalse(shows.isLoading(for: .onTheAir))
        XCTAssertFalse(shows.isLoading(for: .airingToday))

        for feedType in TVShowFeedType.allCases {
            let tab = TVShowFeedTabContent(
                viewModel: shows,
                feedType: feedType,
                detailRouteBuilder: { _ in 1 }
            )
            try tab.body.inspect().callOnAppear()
            XCTAssertTrue(shows.isLoading(for: feedType))
        }
    }
}
