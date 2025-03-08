@testable import TMDB_Shared_Backend
import XCTest

final class FavoriteTVShowsTests: XCTestCase {
    func testFavoriteTVShowsParsing() throws {
        let bundle = Bundle.module
        let url = try XCTUnwrap(bundle.url(forResource: "fav_tv", withExtension: "json"))
        let data = try XCTUnwrap(Data(contentsOf: url))

        var shows: TVShowListResultModel?
        XCTAssertNoThrow(shows = try JSONDecoder().decode(TVShowListResultModel.self, from: data))

        let unwrappedShows = try XCTUnwrap(shows)
        let fourthShow = try XCTUnwrap(unwrappedShows.results[3])

        XCTAssertEqual(fourthShow.name, "Cuarto milenio")
        XCTAssertEqual(fourthShow.id, 61583)
        XCTAssertEqual(fourthShow.first_air_date, "2005-11-13")
        XCTAssertEqual(fourthShow.vote_average, 7.5)
    }
}
