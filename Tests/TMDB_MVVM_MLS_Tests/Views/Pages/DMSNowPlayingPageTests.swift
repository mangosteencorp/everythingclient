import SwiftUI
@testable import TMDB_MVVM_MLS
import TMDB_Shared_UI
import ViewInspector
import XCTest

@available(iOS 16.0, *)
class DMSNowPlayingPageTests: XCTestCase {
    var page: DMSNowPlayingPage!

    override func setUp() {
        super.setUp()
        page = DMSNowPlayingPage(apiKey: "test_key")
    }

    func testInitialization() {
        XCTAssertNotNil(page)
        XCTAssertEqual(APIKeys.tmdbKey, "test_key")
    }

    func testNavigationViewStructure() throws {
        let content = DMSNowPlayingPage(apiKey: "test_key")
        let navigationView = try content.inspect().find(ViewType.NavigationView.self)
        XCTAssertNotNil(navigationView)
        let searchBar = try content.inspect().find(viewWithAccessibilityIdentifier: "movielist1.searchbar")
        XCTAssertNotNil(searchBar)
        let groupView = try content.inspect().find(viewWithAccessibilityIdentifier: "movielist1.group")
        try groupView.callOnAppear()
        XCTAssertTrue(content.viewModel.isLoading)
    }

    func testErrorState() throws {
        // Set error state
        let errorMessage = "Test error message"
        page.viewModel.errorMessage = errorMessage
        page.viewModel.isLoading = false

        // Find error text
        let errorText = try page.inspect().find(ViewType.Text.self)
        XCTAssertEqual(try errorText.string(), errorMessage)
    }

    func testMovieListState() throws {
        // Set movies state
        let movie = sampleApeMovie
        page.viewModel.movies = [movie]
        page.viewModel.isLoading = false
        page.viewModel.errorMessage = nil

        // Find List view
        let list = try page.inspect().find(ViewType.List.self)
        XCTAssertNotNil(list)

        // Verify movie row
        let movieRow = try list.find(NavigationMovieRow.self)
        XCTAssertNotNil(movieRow)
        let navRow = try movieRow.find(viewWithAccessibilityIdentifier: "movielist1.movierow\(sampleApeMovie.id)")
        try navRow.callOnAppear()
    }

    func testOnAppearFetchesMovies() throws {
        // Find VStack and trigger onAppear
        let vstack = try page.inspect().find(ViewType.VStack.self)
        try vstack.callOnAppear()

        // Verify loading state is triggered
        XCTAssertTrue(page.viewModel.isLoading)
    }

    func testSearchQueryBinding() throws {
        // Find TextField
        let textField = try page.inspect().find(ViewType.TextField.self)

        // Test binding
        try textField.setInput("test query")
        XCTAssertEqual(page.viewModel.searchQuery, "test query")
    }
}
