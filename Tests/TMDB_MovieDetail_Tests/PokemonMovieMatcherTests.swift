import Tests_Shared_Helpers
@testable import TMDB_MovieDetail
import XCTest

final class PokemonMovieMatcherTests: XCTestCase {
    private func movie(
        title: String = "Dune",
        overview: String = "Paul Atreides",
        keywords: [(id: Int, name: String)] = []
    ) throws -> Movie {
        let keywordJSON = keywords
            .map { #"{"id": \#($0.id), "name": "\#($0.name)"}"# }
            .joined(separator: ",")
        var json = TMDBJSON.movieDetail(title: title)
        json = json.replacingOccurrences(of: #""overview": "Paul Atreides""#, with: #""overview": "\#(overview)""#)
        json = json.replacingOccurrences(
            of: #""status": "Released""#,
            with: #""status": "Released", "keywords": {"keywords": [\#(keywordJSON)]}"#
        )
        return try JSONFixture.decode(Movie.self, from: json)
    }

    func testMatchesOnKeywordId() throws {
        XCTAssertTrue(PokemonMovieMatcher.shouldShowPokedexButton(for: try movie(keywords: [(11_551, "anything")])))
        XCTAssertTrue(PokemonMovieMatcher.shouldShowPokedexButton(for: try movie(keywords: [(222_288, "anything")])))
    }

    func testMatchesOnKeywordName() throws {
        XCTAssertTrue(PokemonMovieMatcher.shouldShowPokedexButton(for: try movie(keywords: [(1, "Pocket Monsters")])))
    }

    func testMatchesOnTitleCaseAndAccentInsensitively() throws {
        XCTAssertTrue(PokemonMovieMatcher.shouldShowPokedexButton(for: try movie(title: "POKEMON Detective Pikachu")))
        XCTAssertTrue(PokemonMovieMatcher.shouldShowPokedexButton(for: try movie(title: "Pokémon: The First Movie")))
    }

    func testMatchesOnOverview() throws {
        XCTAssertTrue(PokemonMovieMatcher.shouldShowPokedexButton(for: try movie(overview: "Ash Ketchum sets out.")))
    }

    func testDoesNotMatchAnUnrelatedMovie() throws {
        XCTAssertFalse(PokemonMovieMatcher.shouldShowPokedexButton(for: try movie()))
        XCTAssertFalse(PokemonMovieMatcher.shouldShowPokedexButton(for: try movie(keywords: [(1, "space opera")])))
    }
}
