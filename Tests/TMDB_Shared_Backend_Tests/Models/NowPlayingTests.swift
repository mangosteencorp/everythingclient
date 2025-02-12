@testable import TMDB_Shared_Backend
import XCTest

final class NowPlayingTests: XCTestCase {
    func testNowPlayingParsing() throws {
        let bundle = Bundle.module
        let url = try XCTUnwrap(bundle.url(forResource: "now_playing", withExtension: "json"))
        let data = try XCTUnwrap(Data(contentsOf: url))

        var nowPlaying: MovieListResultModel?
        XCTAssertNoThrow(nowPlaying = try JSONDecoder().decode(MovieListResultModel.self, from: data))

        let unwrappedNowPlaying = try XCTUnwrap(nowPlaying)
        let firstMovie = try XCTUnwrap(unwrappedNowPlaying.results.first)

        XCTAssertEqual(firstMovie.title, "Sonic the Hedgehog 3")
        XCTAssertEqual(firstMovie.vote_average, 7.677)
        XCTAssertEqual(firstMovie.release_date, "2024-12-20")
    }
}
