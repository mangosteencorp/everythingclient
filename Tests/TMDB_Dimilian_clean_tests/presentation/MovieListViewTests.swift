import XCTest
import SwiftUI
@testable import TMDB_Dimilian_clean

class MovieListViewTests: XCTestCase {
    func testInitialization() {
        let nowPlayingView = MovieListPage(apiKey: "", type: .nowPlaying)
        XCTAssertNotNil(nowPlayingView, "Should be able to initialize MovieListView with .nowPlaying type")
        
        let upcomingView = MovieListPage(apiKey: "", type: .upcoming)
        XCTAssertNotNil(upcomingView, "Should be able to initialize MovieListView with .upcoming type")
    }
    

}
