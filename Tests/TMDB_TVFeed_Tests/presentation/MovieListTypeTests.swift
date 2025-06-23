@testable import TMDB_TVFeed
import XCTest

class MovieListTypeTests: XCTestCase {
    func testMovieListTypeTitles() {
        XCTAssertEqual(TVShowFeedType.airingToday.title, "Now Playing")
        XCTAssertEqual(TVShowFeedType.onTheAir.title, "Upcoming")
    }

    func testMovieListTypeIcons() {
        XCTAssertEqual(TVShowFeedType.airingToday.iconName, "play.circle")
        XCTAssertEqual(TVShowFeedType.onTheAir.iconName, "calendar")
    }
}
