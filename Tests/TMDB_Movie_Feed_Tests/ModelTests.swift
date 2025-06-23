@testable import TMDB_Movie_Feed
import XCTest

final class ModelTests: XCTestCase {
    var jsonData: Data!

    override func setUp() {
        super.setUp()
        // Load the JSON file from the test bundle
        guard let url = Bundle.module.url(forResource: "nowplaying", withExtension: "json"),
              let data = try? Data(contentsOf: url)
        else {
            XCTFail("Failed to load nowplaying.json")
            return
        }
        jsonData = data
    }

    func testNowPlayingResponseDecoding() throws {
        // When
        let response = try JSONDecoder().decode(NowPlayingResponse.self, from: jsonData)

        // Then
        XCTAssertEqual(response.page, 2)
        XCTAssertEqual(response.totalPages, 3)
        XCTAssertEqual(response.totalResults, 42)
        XCTAssertEqual(response.results.count, 20)

        // Test dates
        XCTAssertNotNil(response.dates)
        XCTAssertEqual(response.dates?.maximum, "2025-02-05")
        XCTAssertEqual(response.dates?.minimum, "2024-12-25")
    }

    func testMovieModelDecoding() throws {
        // When
        let response = try JSONDecoder().decode(NowPlayingResponse.self, from: jsonData)
        let firstMovie = try XCTUnwrap(response.results.first)

        // Then
        XCTAssertEqual(firstMovie.id, 659_956)
        XCTAssertEqual(firstMovie.originalTitle, "Brave the Dark")
        XCTAssertEqual(firstMovie.title, "Brave the Dark")
        XCTAssertEqual(firstMovie.userTitle, "Brave the Dark")
        XCTAssertEqual(firstMovie.posterPath, "/sMmy9CICGEyFDcXM9fIXU2bDEcH.jpg")
        XCTAssertEqual(firstMovie.backdropPath, "/6pxyCuAgJ0uEpbMXmEfJ6NmUrD7.jpg")
        XCTAssertEqual(firstMovie.popularity, 11.393)
        XCTAssertEqual(firstMovie.voteAverage, 5.65)
        XCTAssertEqual(firstMovie.voteCount, 10)
        XCTAssertEqual(firstMovie.releaseDate, "2025-01-24")
        XCTAssertFalse(firstMovie.video)

        // Test date formatting
        let expectedDate = Movie.dateFormatter.date(from: "2025-01-24")
        XCTAssertEqual(firstMovie.releaseDateFormatted, expectedDate)
    }

    func testMovieToMovieRowEntityConversion() throws {
        // Given
        let response = try JSONDecoder().decode(NowPlayingResponse.self, from: jsonData)
        let movie = try XCTUnwrap(response.results.first)

        // When
        let entity = movie.toMovieRowEntity()

        // Then
        XCTAssertEqual(entity.id, movie.id)
        XCTAssertEqual(entity.posterPath, movie.posterPath)
        XCTAssertEqual(entity.title, movie.userTitle)
        XCTAssertEqual(entity.voteAverage, Double(movie.voteAverage))
        XCTAssertEqual(entity.releaseDate, movie.releaseDateFormatted)
        XCTAssertEqual(entity.overview, movie.overview)
    }

    func testMovieWithMissingOptionalFields() throws {
        // Find a movie in the JSON with null fields
        let response = try JSONDecoder().decode(NowPlayingResponse.self, from: jsonData)
        let movieWithNulls = try XCTUnwrap(response.results.first { $0.posterPath == nil })

        // Then
        XCTAssertNil(movieWithNulls.posterPath)
        XCTAssertNil(movieWithNulls.backdropPath)
    }

    func testDateFormatterFormat() {
        // Given
        let dateString = "2025-01-24"

        // When
        let date = Movie.dateFormatter.date(from: dateString)
        let backToString = Movie.dateFormatter.string(from: date!)

        // Then
        XCTAssertNotNil(date)
        XCTAssertEqual(dateString, backToString)
    }
}
