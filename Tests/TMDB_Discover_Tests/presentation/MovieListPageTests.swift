import SwiftUI
import Swinject
@testable import TMDB_Discover
import XCTest

@available(iOS 16.0, *)
class MovieListPageTests: XCTestCase {
    var container: Container!
    var mockViewModel: TVFeedViewModel!

    override func setUp() {
        super.setUp()
        container = Container()
        let assembly = DiscoverAssembly(apiKey: "test_api_key")
        assembly.assemble(container: container)
        mockViewModel = TVFeedViewModel(fetchMoviesUseCase: MockFetchMoviesUseCase())
    }

    func testMovieListPageInitialization() {
        // Given
        let apiKey = "test_api_key"
        let movieGenre = Genre(id: 28, name: "Action")
        let tvGenre = Genre(id: 10765, name: "Sci-Fi")

        // When
        let movieGenrePage = DiscoverListPage(
            container: container,
            apiKey: apiKey,
            type: .discoverWithGenre(movieGenre),
            detailRouteBuilder: { _, _ in 1 }
        )
        let tvGenrePage = DiscoverListPage(
            container: container,
            apiKey: apiKey,
            type: .discoverWithTVGenre(tvGenre),
            detailRouteBuilder: { _, _ in 1 }
        )

        // Then
        XCTAssertNotNil(movieGenrePage)
        XCTAssertNotNil(tvGenrePage)
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
