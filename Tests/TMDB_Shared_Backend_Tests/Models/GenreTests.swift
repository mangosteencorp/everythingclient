@testable import TMDB_Shared_Backend
import XCTest

final class GenreTests: XCTestCase {
    func testGenreParsing() throws {
        let bundle = Bundle.module
        let url = try XCTUnwrap(bundle.url(forResource: "genre_movie", withExtension: "json"))
        let data = try XCTUnwrap(Data(contentsOf: url))

        var genreList: GenreListModel?
        XCTAssertNoThrow(genreList = try JSONDecoder().decode(GenreListModel.self, from: data))

        let unwrappedGenreList = try XCTUnwrap(genreList)

        // Test that we have the expected number of genres
        XCTAssertEqual(unwrappedGenreList.genres.count, 19)

        // Test specific genres
        let actionGenre = try XCTUnwrap(unwrappedGenreList.genres.first { $0.id == 28 })
        XCTAssertEqual(actionGenre.name, "Action")

        let comedyGenre = try XCTUnwrap(unwrappedGenreList.genres.first { $0.id == 35 })
        XCTAssertEqual(comedyGenre.name, "Comedy")

        let dramaGenre = try XCTUnwrap(unwrappedGenreList.genres.first { $0.id == 18 })
        XCTAssertEqual(dramaGenre.name, "Drama")

        let horrorGenre = try XCTUnwrap(unwrappedGenreList.genres.first { $0.id == 27 })
        XCTAssertEqual(horrorGenre.name, "Horror")

        let sciFiGenre = try XCTUnwrap(unwrappedGenreList.genres.first { $0.id == 878 })
        XCTAssertEqual(sciFiGenre.name, "Science Fiction")
    }
}