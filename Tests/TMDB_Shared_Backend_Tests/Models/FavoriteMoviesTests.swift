import XCTest
@testable import TMDB_Shared_Backend

final class FavoriteMoviesTests: XCTestCase {
    func testFavoriteMoviesParsing() throws {
        let bundle = Bundle.module
        let url = try XCTUnwrap(bundle.url(forResource: "fav_mov", withExtension: "json"))
        let data = try XCTUnwrap(try Data(contentsOf: url))
        
        var movies: MovieListResultModel?
        XCTAssertNoThrow(movies = try JSONDecoder().decode(MovieListResultModel.self, from: data))
        
        let unwrappedMovies = try XCTUnwrap(movies)
        let firstMovie = try XCTUnwrap(unwrappedMovies.results.first)
        
        XCTAssertEqual(firstMovie.title, "The Wild Robot")
        XCTAssertEqual(firstMovie.id, 1184918)
        XCTAssertEqual(firstMovie.release_date, "2024-09-12")
        XCTAssertEqual(firstMovie.vote_average, 8.375)
    }
} 
