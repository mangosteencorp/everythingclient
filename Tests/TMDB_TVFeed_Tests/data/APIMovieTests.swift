@testable import TMDB_TVFeed
import XCTest

class APIMovieTests: XCTestCase {
    func testAPIMovieDecoding() throws {
        // Given
        let json = Data("""
        {
            "adult": false,
            "backdrop_path": "/j5CR0gFPjwgmAXkV9HGaF4VMjIW.jpg",
            "genre_ids": [
                10766,
                18,
                35
            ],
            "id": 257064,
            "origin_country": [
                "BR"
            ],
            "original_language": "pt",
            "original_name": "Volta por Cima",
            "overview": "",
            "popularity": 2692.492,
            "poster_path": "/nyN8R0P1Hqwq7ksJz4O2BIAUd4W.jpg",
            "first_air_date": "2024-09-30",
            "name": "Volta por Cima",
            "vote_average": 6.9,
            "vote_count": 11
        }
        """.utf8)

        // When
        let apiMovie = try JSONDecoder().decode(APIMovie.self, from: json)

        // Then
        XCTAssertEqual(apiMovie.id, 257064)
        XCTAssertEqual(apiMovie.title, "Volta por Cima")
        XCTAssertEqual(apiMovie.overview, "")
        XCTAssertEqual(apiMovie.poster_path, "/nyN8R0P1Hqwq7ksJz4O2BIAUd4W.jpg")
        XCTAssertEqual(apiMovie.vote_average, 6.9)
        XCTAssertEqual(apiMovie.popularity, 2692.492)
        XCTAssertEqual(apiMovie.release_date, "2024-09-30")
    }
}

// swiftlint:disable line_length
class MovieListResultModelTests: XCTestCase {
    func testMovieListResultModelDecoding() throws {
        // Given
        let json = Data("""
        {
            "page": 1,
            "results": [
                {
                    "adult": false,
                    "backdrop_path": "/j5CR0gFPjwgmAXkV9HGaF4VMjIW.jpg",
                    "genre_ids": [
                        10766,
                        18,
                        35
                    ],
                    "id": 257064,
                    "origin_country": [
                        "BR"
                    ],
                    "original_language": "pt",
                    "original_name": "Volta por Cima",
                    "overview": "",
                    "popularity": 2692.492,
                    "poster_path": "/nyN8R0P1Hqwq7ksJz4O2BIAUd4W.jpg",
                    "first_air_date": "2024-09-30",
                    "name": "Volta por Cima",
                    "vote_average": 6.9,
                    "vote_count": 11
                },
                {
                    "adult": false,
                    "backdrop_path": "/tPLUHT2cQYJi66aSZZ1qrcu74Zq.jpg",
                    "genre_ids": [
                        10766,
                        18
                    ],
                    "id": 257048,
                    "origin_country": [
                        "BR"
                    ],
                    "original_language": "pt",
                    "original_name": "Garota do Momento",
                    "overview": "Beatriz Dourado, a young black woman marked by abandonment, searches for answers about her past and discovers that her mother, Clarice, left her to pursue her career in Rio de Janeiro. With devastating revelations and a new love, Beatriz faces adversity and transforms her pain into power, fighting to conquer her place in the world.",
                    "popularity": 2690.661,
                    "poster_path": "/jFSkjQSZ5Td52igalpoTQRuHtk.jpg",
                    "first_air_date": "2024-11-04",
                    "name": "She's the One",
                    "vote_average": 8.1,
                    "vote_count": 9
                },
            ],
            "total_pages": 10,
            "total_results": 200
        }
        """.utf8)
        // swiftlint:enable line_length
        // When
        let movieListResult = try JSONDecoder().decode(MovieListResultModel.self, from: json)

        // Then
        XCTAssertNil(movieListResult.dates)
        XCTAssertEqual(movieListResult.page, 1)
        XCTAssertEqual(movieListResult.results.count, 2)
        XCTAssertEqual(movieListResult.totalPages, 10)
        XCTAssertEqual(movieListResult.totalResults, 200)

        let apiMovie = movieListResult.results[0]
        XCTAssertEqual(apiMovie.id, 257064)
    }
}
