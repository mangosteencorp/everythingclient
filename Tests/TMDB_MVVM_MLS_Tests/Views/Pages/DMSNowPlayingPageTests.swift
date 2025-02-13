import SwiftUI
@testable import TMDB_MVVM_MLS
import TMDB_Shared_UI
import ViewInspector
import XCTest

// Mock ViewModel
class MockNowPlayingViewModel: NowPlayingViewModel {
    var fetchNowPlayingMoviesCalled = false
    var searchMoviesCalled = false
    var fetchMoreContentCalled = false
    
    override func fetchNowPlayingMovies() {
        fetchNowPlayingMoviesCalled = true
        // Allow control over loading and error states
        isLoading = false
    }

    override func fetchMoreContentIfNeeded(currentMovieId: Int) {
        fetchMoreContentCalled = true
    }
}

@available(iOS 16.0, *)
class DMSNowPlayingPageTests: XCTestCase {
    var mockViewModel: MockNowPlayingViewModel!
    var page: DMSNowPlayingPage<Int>!

    override func setUp() {
        super.setUp()
        mockViewModel = MockNowPlayingViewModel(apiService: MockAPIService())
        page = DMSNowPlayingPage(apiKey: "", viewModel: mockViewModel, detailRouteBuilder: { _ in 1 })
    }

    override func tearDown() {
        mockViewModel = nil
        page = nil
        super.tearDown()
    }

    func testLoadingState() throws {
        mockViewModel.isLoading = true
        
        let progressView = try page.inspect().find(ViewType.ProgressView.self)
        XCTAssertNotNil(progressView)
        // XCTAssertEqual(try progressView.progressViewStyle(), ProgressViewStyleKey.DefaultStyle())
    }

    func testErrorState() throws {
        let errorMessage = "Test error"
        mockViewModel.errorMessage = errorMessage
        mockViewModel.isLoading = false
        
        let errorText = try page.inspect().find(ViewType.Text.self)
        XCTAssertEqual(try errorText.string(), errorMessage)
    }

    func testMovieListDisplay() throws {
        mockViewModel.movies = [sampleApeMovie]
        mockViewModel.isLoading = false
        mockViewModel.errorMessage = nil
        
        let list = try page.inspect().find(ViewType.List.self)
        XCTAssertNotNil(list)
        
        // Verify movie row exists
        let movieRow = try list.find(NavigationMovieRow<Int>.self)
        XCTAssertNotNil(movieRow)
    }

    func testFetchMoviesOnAppear() throws {
        let vstack = try page.inspect().find(ViewType.VStack.self)
        try vstack.callOnAppear()
        
        XCTAssertTrue(mockViewModel.fetchNowPlayingMoviesCalled)
    }

}
