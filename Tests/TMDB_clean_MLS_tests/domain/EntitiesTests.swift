//
//  DomainUseCaseTests.swift
//  
//
//  Created by Quang on 2024-07-03.
//

import XCTest
@testable import TMDB_clean_MLS
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
        let movie = Movie(id: id, title: title, overview: overview, posterPath: posterPath, voteAverage: voteAverage, popularity: popularity, releaseDate: releaseDate)
        
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
        let movie = Movie(id: id, title: title, overview: overview, posterPath: nil, voteAverage: voteAverage, popularity: popularity, releaseDate: nil)
        
        // Then
        XCTAssertEqual(movie.id, id)
        XCTAssertEqual(movie.title, title)
        XCTAssertEqual(movie.overview, overview)
        XCTAssertNil(movie.posterPath)
        XCTAssertEqual(movie.voteAverage, voteAverage)
        XCTAssertEqual(movie.popularity, popularity)
        XCTAssertNil(movie.releaseDate)
    }
}
