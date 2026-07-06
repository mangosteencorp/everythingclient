import TMDB_MovieDetail
import XCTest

final class MovieOSTSearchQueryBuilderTests: XCTestCase {
    func testSearchTermIncludesMovieTitle() {
        let term = MovieOSTSearchQueryBuilder.searchTerm(for: "Superman")
        XCTAssertEqual(term, "Superman soundtrack")
    }

    func testSearchTermTrimsWhitespace() {
        let term = MovieOSTSearchQueryBuilder.searchTerm(for: "  Dune  ")
        XCTAssertEqual(term, "Dune soundtrack")
    }

    func testSearchTermFallbackForEmptyTitle() {
        let term = MovieOSTSearchQueryBuilder.searchTerm(for: "   ")
        XCTAssertEqual(term, "soundtrack")
    }

    func testIsLikelySoundtrackAlbumMatchesCommonTitles() {
        XCTAssertTrue(MovieOSTSearchQueryBuilder.isLikelySoundtrackAlbum(title: "Superman (Original Motion Picture Soundtrack)"))
        XCTAssertTrue(MovieOSTSearchQueryBuilder.isLikelySoundtrackAlbum(title: "Dune OST"))
        XCTAssertTrue(MovieOSTSearchQueryBuilder.isLikelySoundtrackAlbum(title: "Interstellar Soundtrack"))
    }

    func testIsLikelySoundtrackAlbumRejectsUnrelatedAlbums() {
        XCTAssertFalse(MovieOSTSearchQueryBuilder.isLikelySoundtrackAlbum(title: "Superman - Single"))
        XCTAssertFalse(MovieOSTSearchQueryBuilder.isLikelySoundtrackAlbum(title: "Top Hits 2024"))
    }
}
