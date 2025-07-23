import SwiftUI
@testable import TMDB_Feed
import TMDB_Shared_UI
import ViewInspector
import XCTest

@available(iOS 16.0, *)
class MovieFeedListPageTests: XCTestCase {
    var mockViewModel: MovieFeedViewModel!
    var page: MovieFeedListPage<Int>!

    override func setUp() {
        super.setUp()
        mockViewModel = MovieFeedViewModel(apiService: MockAPIService())
        let mockTVShowViewModel = TVShowFeedViewModel(apiService: MockAPIService())
        page = MovieFeedListPage(
            movieViewModel: mockViewModel,
            tvShowViewModel: mockTVShowViewModel,
            detailRouteBuilder: { _ in 1 },
            tvShowDetailRouteBuilder: { _ in 1 }
        )
    }

    override func tearDown() {
        mockViewModel = nil
        page = nil
        super.tearDown()
    }

    func testInitialState() {
        let mockTVShowViewModel = TVShowFeedViewModel(apiService: MockAPIService())
        let pageSelfCreatedVM = MovieFeedListPage(
            movieViewModel: MovieFeedViewModel(apiService: MockAPIService()),
            tvShowViewModel: mockTVShowViewModel,
            detailRouteBuilder: { _ in 1 },
            tvShowDetailRouteBuilder: { _ in 1 }
        )
        XCTAssertNotNil(pageSelfCreatedVM)
    }

    func testLoadingState() throws {
        mockViewModel.state = .loading

        let progressView = try page.inspect().find(ViewType.ProgressView.self)
        XCTAssertNotNil(progressView)
    }

    func testErrorState() throws {
        let errorMessage = "Test error"
        mockViewModel.state = .error(errorMessage)

        let errorText = try page.inspect().find(ViewType.Text.self)
        XCTAssertEqual(try errorText.string(), errorMessage)
    }

    func testMovieListDisplay() throws {
        mockViewModel.state = .loaded([sampleApeMovie])

        let list = try page.inspect().find(ViewType.List.self)
        XCTAssertNotNil(list)

        let movieRow = try list.find(NavigationMovieRow<Int>.self)
        XCTAssertNotNil(movieRow)
    }

    func testDebugInitializer() throws {
        // Given
        let testViewModel = mockViewModel!
        let testMovie = Movie(id: 1, originalTitle: "Test", title: "Test", overview: "Test",
                            posterPath: nil, backdropPath: nil, popularity: 0,
                            voteAverage: 0, voteCount: 0, releaseDate: nil,
                            genres: nil, video: false)

        // When
        testViewModel.state = .loaded([testMovie])
        let mockTVShowViewModel = TVShowFeedViewModel(apiService: MockAPIService())
        let testPage = MovieFeedListPage(
            movieViewModel: testViewModel,
            tvShowViewModel: mockTVShowViewModel,
            detailRouteBuilder: { _ in 1 },
            tvShowDetailRouteBuilder: { _ in 1 }
        )

        // Then
        let list = try testPage.inspect().find(ViewType.List.self)
        XCTAssertNotNil(list)

        let movieRow = try list.find(NavigationMovieRow<Int>.self)
        XCTAssertNotNil(movieRow)
    }

    func testDebugInitializerWithSearchResults() throws {
        // Given
        let testViewModel = mockViewModel!
        let searchMovie = Movie(id: 2, originalTitle: "Search", title: "Search", overview: "Search",
                              posterPath: nil, backdropPath: nil, popularity: 0,
                              voteAverage: 0, voteCount: 0, releaseDate: nil,
                              genres: nil, video: false)

        // When
        testViewModel.state = .searchResults([searchMovie])
        let mockTVShowViewModel = TVShowFeedViewModel(apiService: MockAPIService())
        let testPage = MovieFeedListPage(
            movieViewModel: testViewModel,
            tvShowViewModel: mockTVShowViewModel,
            detailRouteBuilder: { _ in 1 },
            tvShowDetailRouteBuilder: { _ in 1 }
        )

        // Then
        let list = try testPage.inspect().find(ViewType.List.self)
        XCTAssertNotNil(list)

        let movieRow = try list.find(NavigationMovieRow<Int>.self)
        XCTAssertNotNil(movieRow)
    }
}
