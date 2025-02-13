import SwiftUI
import Swinject
@testable import TMDB_clean_MLS
import XCTest

@available(iOS 16.0, *)
class MovieListPageTests: XCTestCase {
    var container: Container!
    var mockViewModel: MoviesViewModel!

    override func setUp() {
        super.setUp()
        container = Container()
        let assembly = MovieAssembly()
        assembly.assemble(container: container)
        mockViewModel = MoviesViewModel(fetchMoviesUseCase: MockFetchMoviesUseCase())
    }

    func testMovieListPageInitialization() {
        // Given
        let apiKey = "test_api_key"

        // When
        let nowPlayingPage = MovieListPage(container: container, apiKey: apiKey, type: .nowPlaying, detailRouteBuilder: {_ in 1})
        let upcomingPage = MovieListPage(container: container, apiKey: apiKey, type: .upcoming, detailRouteBuilder: {_ in 1})

        // Then
        XCTAssertNotNil(nowPlayingPage)
        XCTAssertNotNil(upcomingPage)
        XCTAssertEqual(APIKeys.tmdbKey, apiKey)
    }

    func testMovieListPageViewStates() {
        // Given
        let page = MovieListPage(container: container, apiKey: "test_key", type: .nowPlaying, detailRouteBuilder: {_ in 1})

        // Test Loading State
        page.viewModel.isLoading = true
        let loadingView = page.body
        let loadingContent = findViewWithId(loadingView, viewId: "loadingView")
        XCTAssertNotNil(loadingContent, "Loading view should be visible when isLoading is true")

        // Test Error State
        page.viewModel.isLoading = false
        page.viewModel.errorMessage = "Test Error"
        let errorView = page.body
        let errorContent = findViewWithId(errorView, viewId: "errorView")
        XCTAssertNotNil(errorContent, "Error view should be visible when error message exists")

        // Test Content State
        page.viewModel.errorMessage = nil
        page.viewModel.movies = [Movie(
            id: 1,
            title: "Test Movie",
            overview: "Overview",
            posterPath: nil,
            voteAverage: 7.5,
            popularity: 100.0,
            releaseDate: nil
        )]
        let contentView = page.body
        let movieListContent = findViewWithId(contentView, viewId: "movieListContent")
        XCTAssertNotNil(movieListContent, "MovieListContent should be visible when there are movies")
    }

    func testNavigationTitle() {
        // Given
        let nowPlayingPage = MovieListPage(container: container, apiKey: "test_key", type: .nowPlaying, detailRouteBuilder: {_ in 1})
        let upcomingPage = MovieListPage(container: container, apiKey: "test_key", type: .upcoming, detailRouteBuilder: {_ in 1})

        // Then
        XCTAssertEqual(nowPlayingPage.type.title, "Now Playing")
        XCTAssertEqual(upcomingPage.type.title, "Upcoming")
    }

    // Helper function to find a view with specific ID in the view hierarchy
    private func findViewWithId(_ view: Any, viewId: String) -> Any? {
        let mirror = Mirror(reflecting: view)

        // Check if current view has the ID we're looking for
        if let id = mirror.descendant("id") as? String, id == viewId {
            return view
        }

        // Recursively search through child views
        for child in mirror.children {
            if let found = findViewWithId(child.value, viewId: viewId) {
                return found
            }
        }

        return nil
    }
}
