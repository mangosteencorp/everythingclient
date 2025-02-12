import SwiftUI
import Swinject
@testable import TMDB_clean_MLS
import ViewInspector
import XCTest

@available(iOS 16.0, *)
class MovieListViewTests: XCTestCase {
    func testInitialization() {
        let nowPlayingView = MovieListPage(container: Container(), apiKey: "", type: .nowPlaying)
        XCTAssertNotNil(nowPlayingView, "Should be able to initialize MovieListView with .nowPlaying type")

        let upcomingView = MovieListPage(container: Container(), apiKey: "", type: .upcoming)
        XCTAssertNotNil(upcomingView, "Should be able to initialize MovieListView with .upcoming type")
    }

    func testOnAppearCallsFetchMovies() throws {
        // Given
        let page = MovieListPage(container: Container(), apiKey: "test_key", type: .nowPlaying)

        // When
        let groupView = try page.inspect().find(viewWithAccessibilityIdentifier: "movieListPage.group")
        try groupView.callOnAppear()
        // Then
        XCTAssertTrue(page.viewModel.isLoading)
    }
}
