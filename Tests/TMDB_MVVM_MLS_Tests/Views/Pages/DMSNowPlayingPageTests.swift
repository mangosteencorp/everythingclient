import SwiftUI
@testable import TMDB_MVVM_MLS
import TMDB_Shared_UI
import ViewInspector
import XCTest

@available(iOS 16.0, *)
class DMSNowPlayingPageTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    func testInitialization() {
        let page = DMSNowPlayingPage(apiKey: "test_key", detailRouteBuilder: {_ in 1})
        XCTAssertNotNil(page)
        XCTAssertEqual(APIKeys.tmdbKey, "test_key")
    }

    func testNavigationViewStructure() throws {
        let content = DMSNowPlayingPage(apiKey: "test_key", detailRouteBuilder: {_ in 1})
        let navigationView = try content.inspect().find(ViewType.NavigationView.self)
        XCTAssertNotNil(navigationView)
        let searchBar = try content.inspect().find(viewWithAccessibilityIdentifier: "movielist1.searchbar")
        XCTAssertNotNil(searchBar)
        let groupView = try content.inspect().find(viewWithAccessibilityIdentifier: "movielist1.group")
        try groupView.callOnAppear()
        XCTAssertTrue(content.viewModel.isLoading)
    }

    func testErrorState() throws {
        let page = DMSNowPlayingPage(apiKey: "test_key", detailRouteBuilder: {_ in 1})
        
        // Create a hosting controller to properly initialize the view
        let hostingController = UIHostingController(rootView: page)
        _ = hostingController.view
        
        // Set error state
        let errorMessage = "Test error message"
        page.viewModel.errorMessage = errorMessage
        page.viewModel.isLoading = false

        // Find error text
        let errorText = try page.inspect().find(ViewType.Text.self)
        XCTAssertEqual(try errorText.string(), errorMessage)
    }

    func testMovieListState() throws {
        let page = DMSNowPlayingPage(apiKey: "test_key", detailRouteBuilder: {_ in 1})
        
        // Create a hosting controller to properly initialize the view
        let hostingController = UIHostingController(rootView: page)
        _ = hostingController.view
        
        // Now we can safely access and modify the viewModel
        let movie = sampleApeMovie
        page.viewModel.movies = [movie]
        page.viewModel.isLoading = false
        page.viewModel.errorMessage = nil

        // Find List view
        let list = try page.inspect().find(ViewType.List.self)
        XCTAssertNotNil(list)

        // Verify movie row
        let movieRow = try list.find(NavigationMovieRow<Int>.self)
        XCTAssertNotNil(movieRow)
        let navRow = try movieRow.find(viewWithAccessibilityIdentifier: "movielist1.movierow\(sampleApeMovie.id)")
        try navRow.callOnAppear()
    }

    func testOnAppearFetchesMovies() throws {
        let page = DMSNowPlayingPage(apiKey: "test_key", detailRouteBuilder: {_ in 1})
        
        // Create a hosting controller to properly initialize the view
        let hostingController = UIHostingController(rootView: page)
        _ = hostingController.view
        
        // Find VStack and trigger onAppear
        let vstack = try page.inspect().find(ViewType.VStack.self)
        try vstack.callOnAppear()

        // Verify loading state is triggered
        XCTAssertTrue(page.viewModel.isLoading)
    }

    func testSearchQueryBinding() throws {
        let page = DMSNowPlayingPage(apiKey: "test_key", detailRouteBuilder: {_ in 1})
        
        // Create a hosting controller to properly initialize the view
        let hostingController = UIHostingController(rootView: page)
        _ = hostingController.view
        
        // Find TextField
        let textField = try page.inspect().find(ViewType.TextField.self)

        // Test binding
        try textField.setInput("test query")
        XCTAssertEqual(page.viewModel.searchQuery, "test query")
    }
}
