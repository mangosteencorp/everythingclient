import Combine
@testable import TMDB_Feed
import XCTest

final class MockAPIService: APIServiceProtocol {
    var mockNowPlayingResult: Result<MovieListResponse, Error>?
    var mockSearchResult: Result<MovieListResponse, Error>?
    var mockTVResult: Result<TVShowListResponse, Error>?
    var mockTVSearchResult: Result<TVShowListResponse, Error>?

    func fetchNowPlayingMovies(page: Int?, additionalParams: AdditionalMovieListParams?) async -> Result<MovieListResponse, Error> {
        mockNowPlayingResult ?? .failure(NSError(domain: "Test", code: -1))
    }

    func searchMovies(query: String, page: Int?) async -> Result<MovieListResponse, Error> {
        mockSearchResult ?? .failure(NSError(domain: "Test", code: -1))
    }

    func searchMovies(query: String, page: Int?, filters: TMDB_Feed.SearchFilters?) async -> Result<TMDB_Feed.MovieListResponse, any Error> {
        mockSearchResult ?? .failure(NSError(domain: "Test", code: -1))
    }

    func fetchUpcomingMovies(page: Int?, additionalParams: TMDB_Feed.AdditionalMovieListParams?) async -> Result<TMDB_Feed.MovieListResponse, any Error> {
        mockNowPlayingResult ?? .failure(NSError(domain: "Test", code: -1))
    }

    func fetchTopRatedMovies(page: Int?, additionalParams: TMDB_Feed.AdditionalMovieListParams?) async -> Result<TMDB_Feed.MovieListResponse, any Error> {
        mockNowPlayingResult ?? .failure(NSError(domain: "Test", code: -1))
    }

    func fetchPopularMovies(page: Int?, additionalParams: TMDB_Feed.AdditionalMovieListParams?) async -> Result<TMDB_Feed.MovieListResponse, any Error> {
        mockNowPlayingResult ?? .failure(NSError(domain: "Test", code: -1))
    }

    func fetchAiringTodayTVShows(page: Int?, additionalParams: TMDB_Feed.AdditionalMovieListParams?) async -> Result<TMDB_Feed.TVShowListResponse, Error> {
        mockTVResult ?? .failure(NSError(domain: "Test", code: -1))
    }

    func fetchOnTheAirTVShows(page: Int?, additionalParams: TMDB_Feed.AdditionalMovieListParams?) async -> Result<TMDB_Feed.TVShowListResponse, Error> {
        mockTVResult ?? .failure(NSError(domain: "Test", code: -1))
    }

    func searchTVShows(query: String, page: Int?) async -> Result<TMDB_Feed.TVShowListResponse, Error> {
        mockTVSearchResult ?? .failure(NSError(domain: "Test", code: -1))
    }

    func searchTVShows(query: String, page: Int?, filters: TMDB_Feed.SearchFilters?) async -> Result<TMDB_Feed.TVShowListResponse, Error> {
        mockTVSearchResult ?? .failure(NSError(domain: "Test", code: -1))
    }
}

final class MovieFeedViewModelTests: XCTestCase {
    var viewModel: MovieFeedViewModel!
    var mockAPIService: MockAPIService!
    var cancellables: Set<AnyCancellable>!
    var cache: FeedResponseCache!

    override func setUp() {
        super.setUp()
        mockAPIService = MockAPIService()
        cache = FeedResponseCache(defaults: UserDefaults(suiteName: "MovieFeedVM.\(UUID().uuidString)")!)
        viewModel = MovieFeedViewModel(apiService: mockAPIService, cache: cache)
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        viewModel = nil
        mockAPIService = nil
        cancellables = nil
        cache = nil
        super.tearDown()
    }

    func testFetchNowPlayingMoviesSuccess() async {
        let expectedMovies = [sampleApeMovie]
        mockAPIService.mockNowPlayingResult = .success(MovieListResponse(
            dates: nil,
            page: 1,
            results: expectedMovies,
            totalPages: 1,
            totalResults: 1
        ))

        viewModel.fetchNowPlayingMovies()

        let expectation = XCTestExpectation(description: "Fetch movies")
        viewModel.$state
            .dropFirst()
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
        let expectedError = NSError(domain: "Test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        mockAPIService.mockNowPlayingResult = .failure(expectedError)

        viewModel.fetchNowPlayingMovies()

        let expectation = XCTestExpectation(description: "Fetch movies error")
        viewModel.$state
            .dropFirst()
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
        let searchResults = [sampleEmptyMovie]
        mockAPIService.mockSearchResult = .success(MovieListResponse(
            dates: nil,
            page: 1,
            results: searchResults,
            totalPages: 1,
            totalResults: 1
        ))

        viewModel.searchQuery = "test"

        let expectation = XCTestExpectation(description: "Search movies")
        viewModel.$state
            .dropFirst()
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
        let initialMovies = [sampleApeMovie]
        let additionalMovies = [sampleEmptyMovie]

        mockAPIService.mockNowPlayingResult = .success(MovieListResponse(
            dates: nil,
            page: 1,
            results: initialMovies,
            totalPages: 2,
            totalResults: 2
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

        mockAPIService.mockNowPlayingResult = .success(MovieListResponse(
            dates: nil,
            page: 2,
            results: additionalMovies,
            totalPages: 2,
            totalResults: 2
        ))

        viewModel.fetchMoreContentIfNeeded(currentMovieId: initialMovies.last!.id)

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

    func testClearSearchRestoresInitialState() async {
        let searchResults = [sampleEmptyMovie]
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
                if case .searchResults = state {
                    searchExpectation.fulfill()
                }
            }
            .store(in: &cancellables)

        await fulfillment(of: [searchExpectation], timeout: 1.0)

        viewModel.clearSearchAndRetry()
        XCTAssertEqual(viewModel.searchQuery, "")
        if case .initial = viewModel.state {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected initial after clear search")
        }
    }

    func testCacheFallbackOnNetworkFailure() async {
        cache.saveMovies([sampleApeMovie], for: .popular)
        let vm = MovieFeedViewModel(apiService: mockAPIService, cache: cache)
        mockAPIService.mockNowPlayingResult = .failure(NSError(domain: "Test", code: -2))

        await vm.refresh(.popular)

        XCTAssertEqual(vm.movies(for: .popular).first?.id, sampleApeMovie.id)
        if case .loaded(let movies) = vm.state {
            XCTAssertEqual(movies.first?.id, sampleApeMovie.id)
        } else {
            XCTFail("Expected loaded from cache")
        }
    }
}
