@testable import TMDB_Discover
import XCTest

class MovieListTypeTests: XCTestCase {
    func testMovieListTypeTitles() {
        let movieGenre = Genre(id: 28, name: "Action")
        let tvGenre = Genre(id: 10765, name: "Sci-Fi")
        XCTAssertEqual(TVShowFeedType.discoverWithGenre(movieGenre).title, "Action Movies")
        XCTAssertEqual(TVShowFeedType.discoverWithTVGenre(tvGenre).title, "Sci-Fi TV Shows")
    }
}
