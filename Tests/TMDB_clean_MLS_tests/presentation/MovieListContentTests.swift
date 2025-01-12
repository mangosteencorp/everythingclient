import XCTest
import SwiftUI
@testable import TMDB_clean_MLS
import TMDB_Shared_UI

@available(iOS 16.0, *)
class MovieListContentTests: XCTestCase {
    func testMovieListContentInitialization() {
        // Given
        let movies = [
            Movie(
                id: 1,
                title: "Test Movie",
                overview: "Test Overview",
                posterPath: "/test.jpg",
                voteAverage: 7.5,
                popularity: 100.0,
                releaseDate: Movie.dateFormatter.date(from: "2024-01-01")
            )
        ]
        
        // When
        let content = MovieListContent(movies: movies)
        
        // Then
        let mirror = Mirror(reflecting: content)
        guard let moviesProperty = mirror.children.first(where: { $0.label == "movies" })?.value as? [Movie] else {
            XCTFail("Movies property not found or wrong type")
            return
        }
        
        XCTAssertEqual(moviesProperty.count, 1)
        XCTAssertEqual(moviesProperty[0].id, movies[0].id)
        XCTAssertEqual(moviesProperty[0].title, movies[0].title)
        XCTAssertEqual(moviesProperty[0].overview, movies[0].overview)
        XCTAssertEqual(moviesProperty[0].posterPath, movies[0].posterPath)
        XCTAssertEqual(moviesProperty[0].voteAverage, movies[0].voteAverage)
        XCTAssertEqual(moviesProperty[0].popularity, movies[0].popularity)
        XCTAssertEqual(moviesProperty[0].releaseDate, movies[0].releaseDate)
    }
} 