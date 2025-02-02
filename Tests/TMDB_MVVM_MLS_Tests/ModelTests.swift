import XCTest
@testable import TMDB_MVVM_MLS

final class ModelTests: XCTestCase {
    var jsonData: Data!
    
    override func setUp() {
        super.setUp()
        // Load the JSON file from the test bundle
        guard let url = Bundle.module.url(forResource: "nowplaying", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
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
        XCTAssertEqual(firstMovie.id, 659956)
        XCTAssertEqual(firstMovie.original_title, "Brave the Dark")
        XCTAssertEqual(firstMovie.title, "Brave the Dark")
        XCTAssertEqual(firstMovie.userTitle, "Brave the Dark")
        XCTAssertEqual(firstMovie.poster_path, "/sMmy9CICGEyFDcXM9fIXU2bDEcH.jpg")
        XCTAssertEqual(firstMovie.backdrop_path, "/6pxyCuAgJ0uEpbMXmEfJ6NmUrD7.jpg")
        XCTAssertEqual(firstMovie.popularity, 11.393)
        XCTAssertEqual(firstMovie.vote_average, 5.65)
        XCTAssertEqual(firstMovie.vote_count, 10)
        XCTAssertEqual(firstMovie.release_date, "2025-01-24")
        XCTAssertFalse(firstMovie.video)
        
        // Test date formatting
        let expectedDate = Movie.dateFormatter.date(from: "2025-01-24")
        XCTAssertEqual(firstMovie.releaseDate, expectedDate)
    }
    
    func testMovieToMovieRowEntityConversion() throws {
        // Given
        let response = try JSONDecoder().decode(NowPlayingResponse.self, from: jsonData)
        let movie = try XCTUnwrap(response.results.first)
        
        // When
        let entity = movie.toMovieRowEntity()
        
        // Then
        XCTAssertEqual(entity.id, movie.id)
        XCTAssertEqual(entity.posterPath, movie.poster_path)
        XCTAssertEqual(entity.title, movie.userTitle)
        XCTAssertEqual(entity.voteAverage, Double(movie.vote_average))
        XCTAssertEqual(entity.releaseDate, movie.releaseDate)
        XCTAssertEqual(entity.overview, movie.overview)
    }
    
    func testMovieWithMissingOptionalFields() throws {
        // Find a movie in the JSON with null fields
        let response = try JSONDecoder().decode(NowPlayingResponse.self, from: jsonData)
        let movieWithNulls = try XCTUnwrap(response.results.first { $0.poster_path == nil })
        
        // Then
        XCTAssertNil(movieWithNulls.poster_path)
        XCTAssertNil(movieWithNulls.backdrop_path)
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