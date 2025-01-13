//
//  MovieRepositoryImplTests.swift
//  
//
//  Created by Quang on 2024-07-14.
//

import XCTest
@testable import TMDB_clean_MLS
class MovieRepositoryImplTests: XCTestCase {

    var repository: MovieRepositoryImpl!
    var mockAPIService: MockAPIService!

    override func setUp() {
        super.setUp()
        mockAPIService = MockAPIService()
        repository = MovieRepositoryImpl(apiService: mockAPIService)
    }

    func testFetchMoviesSuccess() async {
        // Setup mock API to return success...
        let expectation = XCTestExpectation(description: "Fetch movies succeeds")
        mockAPIService.resultToReturn = .success(MockData.movieListResultModel)
        let result = await repository.fetchNowPlayingMovies()
        if case .success(let movies) = result {
            XCTAssert(!movies.isEmpty, "Movies should not be empty on success")
            XCTAssertEqual(movies.count,2, "Movies should not be empty on success")
        } else {
            XCTFail("Expected successful movie fetch")
        }
        
    }
    
    func testFetchMoviesFailure() async {
        // Setup mock API to return success...
        let expectation = XCTestExpectation(description: "Fetch movies succeeds")
        mockAPIService.resultToReturn = .failure(MockError.noResponse)
        let result = await repository.fetchUpcomingMovies()
        if case .success(let movies) = result {
            XCTFail()
        }
        
    }
    
}
class MockAPIService: APIServiceProtocol {
    func fetchMovies(endpoint: MovieListType) async -> Result<MovieListResultModel, Error> {
        return resultToReturn ?? .failure(MockError.noResponse)
    }
    
    var resultToReturn: Result<MovieListResultModel, Error>?
}
