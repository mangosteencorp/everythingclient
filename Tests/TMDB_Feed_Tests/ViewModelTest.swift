import Combine
import Foundation
@testable import TMDB_Feed
import TMDB_Shared_Backend
import XCTest

final class MockAPIService: APIServiceProtocol {
    var mockNowPlayingResult: Result<MovieListResponse, Error>?
    var mockSearchResult: Result<MovieListResponse, Error>?
    var mockTVResult: Result<TVShowListResponse, Error>?
    var mockAiringTodayResult: Result<TVShowListResponse, Error>?
    var mockOnTheAirResult: Result<TVShowListResponse, Error>?
    var mockTVSearchResult: Result<TVShowListResponse, Error>?
    var tvFetchDelayNanoseconds: UInt64 = 0

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
        if tvFetchDelayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: tvFetchDelayNanoseconds)
        }
        return mockAiringTodayResult ?? mockTVResult ?? .failure(NSError(domain: "Test", code: -1))
    }

    func fetchOnTheAirTVShows(page: Int?, additionalParams: TMDB_Feed.AdditionalMovieListParams?) async -> Result<TMDB_Feed.TVShowListResponse, Error> {
        if tvFetchDelayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: tvFetchDelayNanoseconds)
        }
        return mockOnTheAirResult ?? mockTVResult ?? .failure(NSError(domain: "Test", code: -1))
    }

    func searchTVShows(query: String, page: Int?) async -> Result<TMDB_Feed.TVShowListResponse, Error> {
        mockTVSearchResult ?? .failure(NSError(domain: "Test", code: -1))
    }

    func searchTVShows(query: String, page: Int?, filters: TMDB_Feed.SearchFilters?) async -> Result<TMDB_Feed.TVShowListResponse, Error> {
        mockTVSearchResult ?? .failure(NSError(domain: "Test", code: -1))
    }
}

final class TVShowFeedViewModelTests: XCTestCase {
    func testConcurrentFeedLoadsUseTheirRequestedFeedType() async {
        let service = MockAPIService()
        service.tvFetchDelayNanoseconds = 80_000_000
        service.mockOnTheAirResult = .success(TVShowListResponse(
            page: 1,
            results: [sampleTVShow(id: 1, name: "On The Air Show")],
            totalPages: 1,
            totalResults: 1
        ))
        service.mockAiringTodayResult = .success(TVShowListResponse(
            page: 1,
            results: [sampleTVShow(id: 2, name: "Airing Today Show")],
            totalPages: 1,
            totalResults: 1
        ))

        let viewModel = TVShowFeedViewModel(apiService: service)
        viewModel.loadFeed(.onTheAir)
        viewModel.loadFeed(.airingToday)

        let deadline = Date().addingTimeInterval(2)
        while Date() < deadline {
            if viewModel.shows(for: .onTheAir).map(\.id) == [1],
               viewModel.shows(for: .airingToday).map(\.id) == [2] {
                break
            }
            try? await Task.sleep(nanoseconds: 40_000_000)
        }

        XCTAssertEqual(viewModel.shows(for: .onTheAir).map(\.id), [1])
        XCTAssertEqual(viewModel.shows(for: .airingToday).map(\.id), [2])
        XCTAssertNil(viewModel.errorMessage(for: .onTheAir))
        XCTAssertNil(viewModel.errorMessage(for: .airingToday))
    }
}

private func sampleTVShow(id: Int, name: String) -> TVShow {
    let json = """
    {
      "adult": false,
      "backdrop_path": null,
      "genre_ids": [],
      "id": \(id),
      "origin_country": ["US"],
      "original_language": "en",
      "original_name": "\(name)",
      "overview": "overview",
      "popularity": 1,
      "poster_path": null,
      "first_air_date": "2024-01-01",
      "name": "\(name)",
      "vote_average": 1,
      "vote_count": 1
    }
    """
    // swiftlint:disable:next force_try
    return try! JSONDecoder().decode(TVShow.self, from: Data(json.utf8))
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

    func testInMemoryFallbackOnNetworkFailure() async {
        mockAPIService.mockNowPlayingResult = .success(MovieListResponse(
            dates: nil,
            page: 1,
            results: [sampleApeMovie],
            totalPages: 1,
            totalResults: 1
        ))
        viewModel.loadFeed(.popular)

        let loaded = XCTestExpectation(description: "loaded")
        viewModel.$state
            .dropFirst()
            .sink { state in
                if case .loaded = state { loaded.fulfill() }
            }
            .store(in: &cancellables)
        await fulfillment(of: [loaded], timeout: 1.0)

        mockAPIService.mockNowPlayingResult = .failure(NSError(domain: "Test", code: -2))
        await viewModel.refresh(.popular)

        XCTAssertEqual(viewModel.movies(for: .popular).first?.id, sampleApeMovie.id)
        if case .loaded(let movies) = viewModel.state {
            XCTAssertEqual(movies.first?.id, sampleApeMovie.id)
        } else {
            XCTFail("Expected loaded from in-memory cache")
        }
    }
}
