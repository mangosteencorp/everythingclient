@testable import TMDB_Discover
import XCTest

class MovieListTypeTests: XCTestCase {
    func testMovieListTypeTitles() {
        XCTAssertEqual(TVShowFeedType.airingToday.title, "Airing Today")
        XCTAssertEqual(TVShowFeedType.onTheAir.title, "On the air")
    }

    func testMovieListTypeIcons() {
        XCTAssertEqual(TVShowFeedType.airingToday.iconName, "play.circle")
        XCTAssertEqual(TVShowFeedType.onTheAir.iconName, "calendar")
    }
}
