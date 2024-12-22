//
//  APIMovieTests.swift
//  
//
//  Created by Quang on 2024-07-03.
//

import XCTest
@testable import TMDB_Dimilian_clean
class APIMovieTests: XCTestCase {
    func testAPIMovieDecoding() throws {
        // Given
        let json = """
        {
            "id": 1,
            "title": "Test Movie",
            "overview": "This is a test movie",
            "poster_path": "/testpath.jpg",
            "vote_average": 7.5,
            "popularity": 100.0,
            "release_date": "2023-06-29"
        }
        """.data(using: .utf8)!
        
        // When
        let apiMovie = try JSONDecoder().decode(APIMovie.self, from: json)
        
        // Then
        XCTAssertEqual(apiMovie.id, 1)
        XCTAssertEqual(apiMovie.title, "Test Movie")
        XCTAssertEqual(apiMovie.overview, "This is a test movie")
        XCTAssertEqual(apiMovie.poster_path, "/testpath.jpg")
        XCTAssertEqual(apiMovie.vote_average, 7.5)
        XCTAssertEqual(apiMovie.popularity, 100.0)
        XCTAssertEqual(apiMovie.release_date, "2023-06-29")
    }
    
    func testAPIMovieDecodingWithMissingOptionalFields() throws {
        // Given
        let json = """
        {
            "id": 2,
            "title": "Another Test Movie",
            "overview": "This is another test movie",
            "vote_average": 8.0,
            "popularity": 95.5
        }
        """.data(using: .utf8)!
        
        // When
        let apiMovie = try JSONDecoder().decode(APIMovie.self, from: json)
        
        // Then
        XCTAssertEqual(apiMovie.id, 2)
        XCTAssertEqual(apiMovie.title, "Another Test Movie")
        XCTAssertEqual(apiMovie.overview, "This is another test movie")
        XCTAssertNil(apiMovie.poster_path)
        XCTAssertEqual(apiMovie.vote_average, 8.0)
        XCTAssertEqual(apiMovie.popularity, 95.5)
        XCTAssertNil(apiMovie.release_date)
    }
}

class MovieListResultModelTests: XCTestCase {
    func testMovieListResultModelDecoding() throws {
        // Given
        let json = """
        {
            "dates": {
                "maximum": "2023-07-29",
                "minimum": "2023-06-29"
            },
            "page": 1,
            "results": [
                {
                    "id": 1,
                    "title": "Test Movie",
                    "overview": "This is a test movie",
                    "poster_path": "/testpath.jpg",
                    "vote_average": 7.5,
                    "popularity": 100.0,
                    "release_date": "2023-06-29"
                }
            ],
            "total_pages": 10,
            "total_results": 200
        }
        """.data(using: .utf8)!
        
        // When
        let movieListResult = try JSONDecoder().decode(MovieListResultModel.self, from: json)
        
        // Then
        XCTAssertEqual(movieListResult.dates.maximum, "2023-07-29")
        XCTAssertEqual(movieListResult.dates.minimum, "2023-06-29")
        XCTAssertEqual(movieListResult.page, 1)
        XCTAssertEqual(movieListResult.results.count, 1)
        XCTAssertEqual(movieListResult.totalPages, 10)
        XCTAssertEqual(movieListResult.totalResults, 200)
        
        let apiMovie = movieListResult.results[0]
        XCTAssertEqual(apiMovie.id, 1)
        XCTAssertEqual(apiMovie.title, "Test Movie")
        XCTAssertEqual(apiMovie.overview, "This is a test movie")
        XCTAssertEqual(apiMovie.poster_path, "/testpath.jpg")
        XCTAssertEqual(apiMovie.vote_average, 7.5)
        XCTAssertEqual(apiMovie.popularity, 100.0)
        XCTAssertEqual(apiMovie.release_date, "2023-06-29")
    }
}
