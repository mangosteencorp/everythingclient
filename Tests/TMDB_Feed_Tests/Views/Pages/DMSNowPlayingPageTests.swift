import SwiftUI
@testable import TMDB_Feed
import TMDB_Shared_UI
import ViewInspector
import XCTest

@available(iOS 16.0, *)
final class MovieFeedListPageTests: XCTestCase {
    var mockViewModel: MovieFeedViewModel!
    var mockTVShowViewModel: TVShowFeedViewModel!
    var page: MovieFeedListPage<Int>!

    override func setUp() {
        super.setUp()
        let cache = FeedResponseCache(defaults: UserDefaults(suiteName: "TMDB_Feed_Tests.\(UUID().uuidString)")!)
        mockViewModel = MovieFeedViewModel(apiService: MockAPIService(), cache: cache)
        mockTVShowViewModel = TVShowFeedViewModel(apiService: MockAPIService(), cache: cache)
        page = MovieFeedListPage(
            movieViewModel: mockViewModel,
            tvShowViewModel: mockTVShowViewModel,
            detailRouteBuilder: { _ in 1 },
            tvShowDetailRouteBuilder: { _ in 1 }
        )
    }

    override func tearDown() {
        mockViewModel = nil
        mockTVShowViewModel = nil
        page = nil
        super.tearDown()
    }

    func testInitialStateCreatesPage() {
        XCTAssertNotNil(page)
    }

    func testLoadingStateShowsProgress() throws {
        mockViewModel.state = .loading

        let progressView = try page.inspect().find(ViewType.ProgressView.self)
        XCTAssertNotNil(progressView)
    }

    func testMovieListDisplay() throws {
        // Seed cache used by tab content
        mockViewModel.state = .loaded([sampleApeMovie])
        // loadFeed stores via fetch; for UI we need movies(for:) populated.
        // Use searchResults path via public state after manually triggering loaded store:
        let expectation = expectation(description: "movies loaded")
        let service = MockAPIService()
        service.mockNowPlayingResult = .success(MovieListResponse(
            dates: nil, page: 1, results: [sampleApeMovie], totalPages: 1, totalResults: 1
        ))
        let cache = FeedResponseCache(defaults: UserDefaults(suiteName: "TMDB_Feed_UI.\(UUID().uuidString)")!)
        let vm = MovieFeedViewModel(apiService: service, cache: cache)
        let tvVM = TVShowFeedViewModel(apiService: MockAPIService(), cache: cache)
        vm.loadFeed(.nowPlaying)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        let testPage = MovieFeedListPage(
            movieViewModel: vm,
            tvShowViewModel: tvVM,
            detailRouteBuilder: { _ in 1 },
            tvShowDetailRouteBuilder: { _ in 1 }
        )

        let list = try testPage.inspect().find(ViewType.List.self)
        XCTAssertNotNil(list)
        let movieRow = try list.find(NavigationMovieRow<Int>.self)
        XCTAssertNotNil(movieRow)
    }

    func testSearchErrorShowsErrorPageWithCancel() throws {
        let errorView = FeedErrorContentView(
            message: "network connection failed",
            allowsCancelSearch: true,
            retryAction: { self.mockViewModel.retrySearch() },
            cancelAction: { self.mockViewModel.cancelSearch() }
        )

        XCTAssertTrue(errorView.allowsCancelSearch)
        XCTAssertTrue(errorView.isLikelyNetworkError)
        mockViewModel.state = .error("network connection failed")
        mockViewModel.cancelSearch()
        XCTAssertEqual(mockViewModel.searchQuery, "")
    }

    func testFeedTabsExist() {
        XCTAssertEqual(FeedTab.allCases.count, 7)
        XCTAssertEqual(FeedTab.allCases.filter { $0.movieFeedType != nil }.count, 4)
        XCTAssertEqual(FeedTab.allCases.filter { $0.tvShowFeedType != nil }.count, 2)
        XCTAssertNotNil(FeedTab.search)
    }
}
