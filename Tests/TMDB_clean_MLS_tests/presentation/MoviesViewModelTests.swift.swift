//
//  MoviesViewModelTests.swift.swift
//
//
//  Created by Quang on 2024-07-03.
//

import XCTest
import Combine
@testable import TMDB_clean_MLS

class MoviesViewModelTests: XCTestCase {
    var viewModel: MoviesViewModel!
    var mockUseCase: MockFetchMoviesUseCase!
    var cancellables = Set<AnyCancellable>()
    
    override func setUp() {
        super.setUp()
        mockUseCase = MockFetchMoviesUseCase()
        viewModel = MoviesViewModel(fetchMoviesUseCase: mockUseCase)
    }
    
    func testFetchMoviesSuccess() {
        // Given
        let expectation = XCTestExpectation(description: "Fetch movies and update state")
        let movies = [Movie(id: 1, title: "Test Movie", overview: "Overview", posterPath: "/path.jpg", voteAverage: 7.5, popularity: 100.0, releaseDate: Date())]
        mockUseCase.mockResult = .success(movies)
        
        // When
        viewModel.fetchMovies()
        
        let _ = viewModel.$movies
            .dropFirst()
            .sink { updatedMovies in
                if !updatedMovies.isEmpty {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)  // Storing the subscription
        
        // Wait for the fetch to complete
        wait(for: [expectation], timeout: 1.0)
        
        // Then
        XCTAssertEqual(viewModel.movies, movies)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testFetchMoviesFailure() {
        // Given
        let expectation = XCTestExpectation(description: "Fetch movies fails and updates error message")
        let error = APIService.APIError.noResponse
        mockUseCase.mockResult = .failure(error)
        
        // When
        viewModel.fetchMovies()
        
        // Using a publisher to observe changes
        let _ = viewModel.$errorMessage
            .dropFirst()  // Drop the initial value
            .sink { updatedErrorMessage in
                if updatedErrorMessage != nil {
                    expectation.fulfill()
                }
            }.store(in: &cancellables)  // Storing the subscription

        // Wait for the fetch to complete
        wait(for: [expectation], timeout: 5.0)
        
        // Then
        XCTAssertTrue(viewModel.movies.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.errorMessage, error.localizedDescription)
    }
}


