import XCTest
import SwiftUI
import Swinject
@testable import TMDB_clean_MLS

@available(iOS 16.0, *)
class MovieListViewTests: XCTestCase {
    func testInitialization() {
        let nowPlayingView = MovieListPage(container: Container(), apiKey: "", type: .nowPlaying)
        XCTAssertNotNil(nowPlayingView, "Should be able to initialize MovieListView with .nowPlaying type")
        
        let upcomingView = MovieListPage(container: Container(), apiKey: "", type: .upcoming)
        XCTAssertNotNil(upcomingView, "Should be able to initialize MovieListView with .upcoming type")
    }
    

}
