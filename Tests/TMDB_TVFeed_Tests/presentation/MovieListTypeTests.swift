@testable import TMDB_TVFeed
import XCTest

class MovieListTypeTests: XCTestCase {
    func testMovieListTypeTitles() {
        XCTAssertEqual(MovieListType.nowPlaying.title, "Now Playing")
        XCTAssertEqual(MovieListType.upcoming.title, "Upcoming")
    }

    func testMovieListTypeIcons() {
        XCTAssertEqual(MovieListType.nowPlaying.iconName, "play.circle")
        XCTAssertEqual(MovieListType.upcoming.iconName, "calendar")
    }
}
