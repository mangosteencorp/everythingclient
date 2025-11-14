@testable import TMDB_Discover
import TMDB_Shared_Backend
import XCTest

class APITVShowDecodingTests: XCTestCase {
    func testTVShowDecoding() throws {
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
        let apiShow = try JSONDecoder().decode(TVShow.self, from: json)

        // Then
        XCTAssertEqual(apiShow.id, 257064)
        XCTAssertEqual(apiShow.name, "Volta por Cima")
        XCTAssertEqual(apiShow.overview, "")
        XCTAssertEqual(apiShow.poster_path, "/nyN8R0P1Hqwq7ksJz4O2BIAUd4W.jpg")
        XCTAssertEqual(apiShow.vote_average, 6.9)
        XCTAssertEqual(apiShow.popularity, 2692.492)
        XCTAssertEqual(apiShow.first_air_date, "2024-09-30")
    }
}

// swiftlint:disable line_length
class TVShowListResultModelTests: XCTestCase {
    func testTVShowListResultModelDecoding() throws {
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
        let tvShowListResult = try JSONDecoder().decode(TVShowListResultModel.self, from: json)

        // Then
        XCTAssertEqual(tvShowListResult.page, 1)
        XCTAssertEqual(tvShowListResult.results.count, 2)
        XCTAssertEqual(tvShowListResult.total_pages, 10)
        XCTAssertEqual(tvShowListResult.total_results, 200)

        let apiShow = tvShowListResult.results[0]
        XCTAssertEqual(apiShow.id, 257064)
    }
}
