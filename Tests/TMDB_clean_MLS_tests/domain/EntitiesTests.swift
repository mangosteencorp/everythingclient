@testable import TMDB_clean_MLS
import XCTest

class MovieTests: XCTestCase {
    func testMovieInitialization() {
        // Given
        let id = 1
        let title = "Test Movie"
        let overview = "This is a test movie"
        let posterPath = "/testpath.jpg"
        let voteAverage: Float = 7.5
        let popularity: Float = 100.0
        let releaseDate = Date()

        // When
        let movie = Movie(
            id: id,
            title: title,
            overview: overview,
            posterPath: posterPath,
            voteAverage: voteAverage,
            popularity: popularity,
            releaseDate: releaseDate
        )

        // Then
        XCTAssertEqual(movie.id, id)
        XCTAssertEqual(movie.title, title)
        XCTAssertEqual(movie.overview, overview)
        XCTAssertEqual(movie.posterPath, posterPath)
        XCTAssertEqual(movie.voteAverage, voteAverage)
        XCTAssertEqual(movie.popularity, popularity)
        XCTAssertEqual(movie.releaseDate, releaseDate)
    }

    func testMovieInitializationWithOptionalFields() {
        // Given
        let id = 2
        let title = "Another Test Movie"
        let overview = "This is another test movie"
        let voteAverage: Float = 8.0
        let popularity: Float = 95.5

        // When
        let movie = Movie(
            id: id,
            title: title,
            overview: overview,
            posterPath: nil,
            voteAverage: voteAverage,
            popularity: popularity,
            releaseDate: nil
        )

        // Then
        XCTAssertEqual(movie.id, id)
        XCTAssertEqual(movie.title, title)
        XCTAssertEqual(movie.overview, overview)
        XCTAssertNil(movie.posterPath)
        XCTAssertEqual(movie.voteAverage, voteAverage)
        XCTAssertEqual(movie.popularity, popularity)
        XCTAssertNil(movie.releaseDate)
    }

    func testToMovieRowEntity() {
        // Given
        let dateFormatter = Movie.dateFormatter
        let releaseDate = dateFormatter.date(from: "2024-01-01")!
        let movie = Movie(
            id: 1,
            title: "Test Movie",
            overview: "Test Overview",
            posterPath: "/test/path.jpg",
            voteAverage: 7.5,
            popularity: 100.0,
            releaseDate: releaseDate
        )

        // When
        let movieRowEntity = movie.toMovieRowEntity()

        // Then
        XCTAssertEqual(movieRowEntity.id, movie.id)
        XCTAssertEqual(movieRowEntity.title, movie.title)
        XCTAssertEqual(movieRowEntity.overview, movie.overview)
        XCTAssertEqual(movieRowEntity.posterPath, movie.posterPath)
        XCTAssertEqual(movieRowEntity.voteAverage, Double(movie.voteAverage))
        XCTAssertEqual(movieRowEntity.releaseDate, movie.releaseDate)
    }

    func testToMovieRowEntityWithNilFields() {
        // Given
        let movie = Movie(
            id: 1,
            title: "Test Movie",
            overview: "Test Overview",
            posterPath: nil,
            voteAverage: 7.5,
            popularity: 100.0,
            releaseDate: nil
        )

        // When
        let movieRowEntity = movie.toMovieRowEntity()

        // Then
        XCTAssertEqual(movieRowEntity.id, movie.id)
        XCTAssertEqual(movieRowEntity.title, movie.title)
        XCTAssertEqual(movieRowEntity.overview, movie.overview)
        XCTAssertNil(movieRowEntity.posterPath)
        XCTAssertEqual(movieRowEntity.voteAverage, Double(movie.voteAverage))
        XCTAssertNil(movieRowEntity.releaseDate)
    }
}
