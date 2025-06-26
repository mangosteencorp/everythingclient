import Combine
@testable import TMDB_Movie_Feed
import XCTest

class MockAPIService: APIServiceProtocol {
    var mockNowPlayingResult: Result<MovieListResponse, Error>?
    var mockSearchResult: Result<MovieListResponse, Error>?

    func fetchNowPlayingMovies(page: Int?, additionalParams: AdditionalMovieListParams?) async -> Result<MovieListResponse, Error> {
        return mockNowPlayingResult ?? .failure(NSError(domain: "Test", code: -1))
    }

    func searchMovies(query: String, page: Int?) async -> Result<MovieListResponse, Error> {
        return mockSearchResult ?? .failure(NSError(domain: "Test", code: -1))
    }

    func searchMovies(query: String, page: Int?, filters: TMDB_Movie_Feed.SearchFilters?) async -> Result<TMDB_Movie_Feed.MovieListResponse, any Error> {
        return mockSearchResult ?? .failure(NSError(domain: "Test", code: -1))
    }

    func fetchUpcomingMovies(page: Int?, additionalParams: TMDB_Movie_Feed.AdditionalMovieListParams?) async -> Result<TMDB_Movie_Feed.MovieListResponse, any Error> {
        return mockNowPlayingResult ?? .failure(NSError(domain: "Test", code: -1))
    }

    func fetchTopRatedMovies(page: Int?, additionalParams: TMDB_Movie_Feed.AdditionalMovieListParams?) async -> Result<TMDB_Movie_Feed.MovieListResponse, any Error> {
        return mockNowPlayingResult ?? .failure(NSError(domain: "Test", code: -1))
    }

    func fetchPopularMovies(page: Int?, additionalParams: TMDB_Movie_Feed.AdditionalMovieListParams?) async -> Result<TMDB_Movie_Feed.MovieListResponse, any Error> {
        return mockNowPlayingResult ?? .failure(NSError(domain: "Test", code: -1))
    }
}

final class MovieFeedViewModelTests: XCTestCase {
    var viewModel: MovieFeedViewModel!
    var mockAPIService: MockAPIService!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockAPIService = MockAPIService()
        viewModel = MovieFeedViewModel(apiService: mockAPIService)
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        viewModel = nil
        mockAPIService = nil
        cancellables = nil
        super.tearDown()
    }

    func testFetchNowPlayingMoviesSuccess() async {
        // Given
        let expectedMovies = [sampleApeMovie]
        mockAPIService.mockNowPlayingResult = .success(MovieListResponse(
            dates: nil,
            page: 1,
            results: expectedMovies,
            totalPages: 1,
            totalResults: 1
        ))

        // When
        viewModel.fetchNowPlayingMovies()

        // Then
        let expectation = XCTestExpectation(description: "Fetch movies")
        viewModel.$state
            .dropFirst() // Skip initial state
            .sink { state in
                if case .loaded(let movies) = state {
                    XCTAssertEqual(movies.count, expectedMovies.count)
                    XCTAssertEqual(movies.first?.id, expectedMovies.first?.id)
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testFetchNowPlayingMoviesFailure() async {
        // Given
        let expectedError = NSError(domain: "Test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        mockAPIService.mockNowPlayingResult = .failure(expectedError)

        // When
        viewModel.fetchNowPlayingMovies()

        // Then
        let expectation = XCTestExpectation(description: "Fetch movies error")
        viewModel.$state
            .dropFirst() // Skip initial state
            .sink { state in
                if case .error(let errorMessage) = state {
                    XCTAssertEqual(errorMessage, expectedError.localizedDescription)
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testSearchMoviesSuccess() async {
        // Given
        let searchResults = [sampleEmptyMovie]
        mockAPIService.mockSearchResult = .success(MovieListResponse(
            dates: nil,
            page: 1,
            results: searchResults,
            totalPages: 1,
            totalResults: 1
        ))

        // When
        viewModel.searchQuery = "test"

        // Then
        let expectation = XCTestExpectation(description: "Search movies")
        viewModel.$state
            .dropFirst() // Skip initial state
            .sink { state in
                if case .searchResults(let movies) = state {
                    XCTAssertEqual(movies.count, searchResults.count)
                    XCTAssertEqual(movies.first?.id, searchResults.first?.id)
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testFetchMoreContent() async {
        // Given
        let initialMovies = [sampleApeMovie]
        let additionalMovies = [sampleEmptyMovie]

        mockAPIService.mockNowPlayingResult = .success(MovieListResponse(
            dates: nil,
            page: 1,
            results: initialMovies,
            totalPages: 2,
            totalResults: 2
        ))

        // Load initial movies
        viewModel.fetchNowPlayingMovies()

        let initialLoadExpectation = XCTestExpectation(description: "Initial load")
        viewModel.$state
            .dropFirst()
            .sink { state in
                if case .loaded = state {
                    initialLoadExpectation.fulfill()
                }
            }
            .store(in: &cancellables)

        await fulfillment(of: [initialLoadExpectation], timeout: 1.0)

        // When fetching more content
        mockAPIService.mockNowPlayingResult = .success(MovieListResponse(
            dates: nil,
            page: 2,
            results: additionalMovies,
            totalPages: 2,
            totalResults: 2
        ))

        viewModel.fetchMoreContentIfNeeded(currentMovieId: initialMovies.last!.id)

        // Then
        let loadMoreExpectation = XCTestExpectation(description: "Load more")
        viewModel.$state
            .dropFirst()
            .sink { state in
                if case .loaded(let movies) = state {
                    XCTAssertEqual(movies.count, initialMovies.count + additionalMovies.count)
                    loadMoreExpectation.fulfill()
                }
            }
            .store(in: &cancellables)

        await fulfillment(of: [loadMoreExpectation], timeout: 1.0)
    }

    func testClearSearchRestoresNowPlayingMovies() async {
        // Given
        let nowPlayingMovies = [sampleApeMovie]
        let searchResults = [sampleEmptyMovie]

        // Set up initial now playing movies
        mockAPIService.mockNowPlayingResult = .success(MovieListResponse(
            dates: nil,
            page: 1,
            results: nowPlayingMovies,
            totalPages: 1,
            totalResults: 1
        ))

        viewModel.fetchNowPlayingMovies()

        let initialLoadExpectation = XCTestExpectation(description: "Initial load")
        viewModel.$state
            .dropFirst()
            .sink { state in
                if case .loaded = state {
                    initialLoadExpectation.fulfill()
                }
            }
            .store(in: &cancellables)

        await fulfillment(of: [initialLoadExpectation], timeout: 1.0)

        // Perform search
        mockAPIService.mockSearchResult = .success(MovieListResponse(
            dates: nil,
            page: 1,
            results: searchResults,
            totalPages: 1,
            totalResults: 1
        ))

        viewModel.searchQuery = "test"

        let searchExpectation = XCTestExpectation(description: "Search complete")
        viewModel.$state
            .dropFirst()
            .sink { state in
                if case .searchResults(let movies) = state {
                    XCTAssertEqual(movies.count, searchResults.count)
                    searchExpectation.fulfill()
                }
            }
            .store(in: &cancellables)

        await fulfillment(of: [searchExpectation], timeout: 1.0)

        // When clearing search
        viewModel.searchQuery = ""

        // Then
        let clearSearchExpectation = XCTestExpectation(description: "Clear search")
        viewModel.$state
            .dropFirst()
            .sink { state in
                if case .loaded(let movies) = state {
                    XCTAssertEqual(movies.count, nowPlayingMovies.count)
                    XCTAssertEqual(movies.first?.id, nowPlayingMovies.first?.id)
                    clearSearchExpectation.fulfill()
                }
            }
            .store(in: &cancellables)

        await fulfillment(of: [clearSearchExpectation], timeout: 1.0)
    }
}
