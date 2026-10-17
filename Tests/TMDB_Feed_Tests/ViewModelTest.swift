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
}

/// Polls until `condition` holds or a second passes; the view models load on their own tasks.
@MainActor
func waitUntil(_ condition: () -> Bool) async {
    let deadline = Date().addingTimeInterval(1)
    while !condition(), Date() < deadline {
        try? await Task.sleep(nanoseconds: 20_000_000)
    }
}

@MainActor
final class TVShowFeedViewModelTests: XCTestCase {
    func testEachViewModelLoadsOnlyItsOwnFeed() async {
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

        let onTheAir = TVShowFeedViewModel(feedType: .onTheAir, apiService: service)
        let airingToday = TVShowFeedViewModel(feedType: .airingToday, apiService: service)
        onTheAir.load()
        airingToday.load()

        await waitUntil { !onTheAir.shows.isEmpty && !airingToday.shows.isEmpty }

        XCTAssertEqual(onTheAir.shows.map(\.id), [1])
        XCTAssertEqual(airingToday.shows.map(\.id), [2])
        XCTAssertNil(onTheAir.errorMessage)
        XCTAssertNil(airingToday.errorMessage)
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

@MainActor
final class MovieFeedViewModelTests: XCTestCase {
    var viewModel: MovieFeedViewModel!
    var mockAPIService: MockAPIService!

    override func setUp() {
        super.setUp()
        mockAPIService = MockAPIService()
        viewModel = MovieFeedViewModel(feedType: .nowPlaying, apiService: mockAPIService)
    }

    override func tearDown() {
        viewModel = nil
        mockAPIService = nil
        super.tearDown()
    }

    func testLoadSuccess() async {
        mockAPIService.mockNowPlayingResult = .success(MovieListResponse(
            dates: nil, page: 1, results: [sampleApeMovie], totalPages: 1, totalResults: 1
        ))

        viewModel.load()
        XCTAssertTrue(viewModel.isLoading, "marked loading before the request returns")

        await waitUntil { !viewModel.movies.isEmpty }
        XCTAssertEqual(viewModel.movies.map(\.id), [sampleApeMovie.id])
        XCTAssertFalse(viewModel.isLoading)
    }

    func testLoadFailureReportsError() async {
        let expectedError = NSError(domain: "Test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        mockAPIService.mockNowPlayingResult = .failure(expectedError)

        viewModel.load()

        await waitUntil { viewModel.errorMessage != nil }
        XCTAssertEqual(viewModel.errorMessage, expectedError.localizedDescription)
        XCTAssertTrue(viewModel.movies.isEmpty)
    }

    func testFetchMoreContentAppendsNextPage() async {
        mockAPIService.mockNowPlayingResult = .success(MovieListResponse(
            dates: nil, page: 1, results: [sampleApeMovie], totalPages: 2, totalResults: 2
        ))
        viewModel.load()
        await waitUntil { !viewModel.movies.isEmpty }

        mockAPIService.mockNowPlayingResult = .success(MovieListResponse(
            dates: nil, page: 2, results: [sampleEmptyMovie], totalPages: 2, totalResults: 2
        ))
        viewModel.fetchMoreContentIfNeeded(currentMovieId: sampleApeMovie.id)

        await waitUntil { viewModel.movies.count == 2 }
        XCTAssertEqual(viewModel.movies.map(\.id), [sampleApeMovie.id, sampleEmptyMovie.id])
    }

    func testAppendingUniqueSkipsRepeatedIDs() {
        // TMDB rankings drift between requests, so page 2 can repeat page 1.
        let combined = [sampleApeMovie].appendingUnique([sampleApeMovie, sampleEmptyMovie])
        XCTAssertEqual(combined.map(\.id), [sampleApeMovie.id, sampleEmptyMovie.id])
    }

    func testRefreshFailureKeepsLoadedMovies() async {
        mockAPIService.mockNowPlayingResult = .success(MovieListResponse(
            dates: nil, page: 1, results: [sampleApeMovie], totalPages: 1, totalResults: 1
        ))
        viewModel.load()
        await waitUntil { !viewModel.movies.isEmpty }

        mockAPIService.mockNowPlayingResult = .failure(NSError(domain: "Test", code: -2))
        await viewModel.refresh()

        XCTAssertEqual(viewModel.movies.map(\.id), [sampleApeMovie.id])
        XCTAssertNil(viewModel.errorMessage)
    }
}
