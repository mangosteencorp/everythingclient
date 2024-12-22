//
//  FetchMoviesUseCaseTests.swift
//  
//
//  Created by Quang on 2024-07-03.
//

import XCTest
@testable import TMDB_Dimilian_clean
// MARK: - FetchMoviesUseCaseTests

class FetchMoviesUseCaseTests: XCTestCase {
    var useCase: FetchNowPlayingMoviesUseCase!
    var mockRepository: MockMovieRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockMovieRepository()
        useCase = FetchNowPlayingMoviesUseCase(movieRepository: mockRepository)
    }

    override func tearDown() {
        useCase = nil
        mockRepository = nil
        super.tearDown()
    }

    func testExecuteSuccess() async {
        // Given
        let expectedMovies = [Movie(id: 1, title: "Test Movie", overview: "Test Overview", posterPath: nil, voteAverage: 7.5, popularity: 100, releaseDate: Date())]
        mockRepository.result = .success(expectedMovies)

        // When
        let result = await useCase.execute()

        // Then
        switch result {
        case .success(let movies):
            XCTAssertEqual(movies, expectedMovies)
        case .failure:
            XCTFail("Expected success, but got failure")
        }
    }

    func testExecuteFailure() async {
        // Given
        let expectedError = NSError(domain: "TestError", code: 0, userInfo: nil)
        mockRepository.result = .failure(expectedError)

        // When
        let result = await useCase.execute()

        // Then
        switch result {
        case .success:
            XCTFail("Expected failure, but got success")
        case .failure(let error):
            XCTAssertEqual(error as NSError, expectedError)
        }
    }
}

