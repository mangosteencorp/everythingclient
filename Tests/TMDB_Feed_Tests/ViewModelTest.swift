import Foundation
import Testing
@testable import TMDB_Feed
import TMDB_Shared_Backend
import TMDB_Shared_UI

final class MockAPIService: APIServiceProtocol {
    var mockNowPlayingResult: Result<MovieListResponse, Error>?
    var mockSearchResult: Result<MovieListResponse, Error>?
    var mockTVResult: Result<TVShowListResponse, Error>?
    var mockAiringTodayResult: Result<TVShowListResponse, Error>?
    var mockOnTheAirResult: Result<TVShowListResponse, Error>?
    var mockTVSearchResult: Result<TVShowListResponse, Error>?
    var tvFetchDelayNanoseconds: UInt64 = 0
    private(set) var nowPlayingCallCount = 0

    func fetchNowPlayingMovies(page: Int?, additionalParams: AdditionalMovieListParams?) async -> Result<MovieListResponse, Error> {
        nowPlayingCallCount += 1
        return mockNowPlayingResult ?? .failure(NSError(domain: "Test", code: -1))
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

extension FeedState {
    enum Kind { case idle, loading, error, loaded, refreshing }

    /// The case without its payload, so tests can compare states of non-`Equatable` items.
    var kind: Kind {
        switch self {
        case .idle: .idle
        case .loading: .loading
        case .error: .error
        case .loaded: .loaded
        case .refreshing: .refreshing
        }
    }

    var errorMessage: String? {
        guard case let .error(message) = self else { return nil }
        return message
    }
}

private func movies(_ results: [Movie], page: Int = 1) -> Result<MovieListResponse, Error> {
    .success(MovieListResponse(dates: nil, page: page, results: results, totalPages: 2, totalResults: 2))
}

@MainActor
struct MovieFeedViewModelTests {
    let service = MockAPIService()
    let viewModel: MovieFeedViewModel

    init() {
        viewModel = MovieFeedViewModel(feedType: .nowPlaying, apiService: service)
    }

    private func loadSampleApeMovie() async {
        service.mockNowPlayingResult = movies([sampleApeMovie])
        viewModel.load()
        await waitUntil { viewModel.state.kind == .loaded }
    }

    @Test func loadGoesFromIdleThroughLoadingToLoaded() async {
        service.mockNowPlayingResult = movies([sampleApeMovie])
        #expect(viewModel.state.kind == .idle)

        viewModel.load()
        #expect(viewModel.state.kind == .loading, "marked loading before the request returns")

        await waitUntil { viewModel.state.kind == .loaded }
        #expect(viewModel.state.items.map(\.id) == [sampleApeMovie.id])
    }

    @Test func loadFailureShowsError() async {
        let error = NSError(domain: "Test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        service.mockNowPlayingResult = .failure(error)

        viewModel.load()
        await waitUntil { viewModel.state.kind == .error }

        #expect(viewModel.state.errorMessage == error.localizedDescription)
        #expect(viewModel.state.items.isEmpty)
    }

    @Test func retryAfterErrorLoadsAgain() async {
        viewModel.load()
        await waitUntil { viewModel.state.kind == .error }

        service.mockNowPlayingResult = movies([sampleApeMovie])
        viewModel.load()
        #expect(viewModel.state.kind == .loading)

        await waitUntil { viewModel.state.kind == .loaded }
        #expect(viewModel.state.items.map(\.id) == [sampleApeMovie.id])
    }

    @Test func loadSendsOneRequestAndLeavesALoadedFeedAlone() async {
        service.mockNowPlayingResult = movies([sampleApeMovie])
        viewModel.load()
        viewModel.load()
        await waitUntil { viewModel.state.kind == .loaded }

        viewModel.load()
        #expect(viewModel.state.kind == .loaded)
        #expect(service.nowPlayingCallCount == 1)
    }

    @Test func refreshReplacesTheFeed() async {
        await loadSampleApeMovie()

        service.mockNowPlayingResult = movies([sampleEmptyMovie])
        await viewModel.refresh()

        #expect(viewModel.state.kind == .loaded)
        #expect(viewModel.state.items.map(\.id) == [sampleEmptyMovie.id])
    }

    @Test func failedRefreshKeepsLoadedMovies() async {
        await loadSampleApeMovie()

        service.mockNowPlayingResult = .failure(NSError(domain: "Test", code: -2))
        await viewModel.refresh()

        #expect(viewModel.state.kind == .loaded)
        #expect(viewModel.state.items.map(\.id) == [sampleApeMovie.id])
    }

    @Test func fetchMoreAppendsOnlyNewMovies() async {
        await loadSampleApeMovie()

        // TMDB rankings drift between requests, so page 2 can repeat page 1.
        service.mockNowPlayingResult = movies([sampleApeMovie, sampleEmptyMovie], page: 2)
        viewModel.fetchMoreContentIfNeeded(currentMovieId: sampleApeMovie.id)

        await waitUntil { viewModel.state.items.count == 2 }
        #expect(viewModel.state.items.map(\.id) == [sampleApeMovie.id, sampleEmptyMovie.id])
    }

    @Test func appendingUniqueSkipsRepeatedIDs() {
        let combined = [sampleApeMovie].appendingUnique([sampleApeMovie, sampleEmptyMovie])
        #expect(combined.map(\.id) == [sampleApeMovie.id, sampleEmptyMovie.id])
    }
}

@MainActor
struct TVShowFeedViewModelTests {
    @Test func eachViewModelLoadsOnlyItsOwnFeed() async {
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

        await waitUntil { onTheAir.state.kind == .loaded && airingToday.state.kind == .loaded }

        #expect(onTheAir.state.items.map(\.id) == [1])
        #expect(airingToday.state.items.map(\.id) == [2])
    }

    @Test func loadFailureShowsError() async {
        let viewModel = TVShowFeedViewModel(feedType: .onTheAir, apiService: MockAPIService())

        viewModel.load()
        #expect(viewModel.state.kind == .loading)

        await waitUntil { viewModel.state.kind == .error }
        #expect(viewModel.state.items.isEmpty)
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
