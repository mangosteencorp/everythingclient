import Combine
import CoreFeatures
import SwiftUI
import TMDB_Shared_Backend

public enum MovieFeedType: String, CaseIterable, Identifiable {
    case nowPlaying
    case popular
    case topRated
    case upcoming

    public var id: String { rawValue }

    public var localizedTitle: String {
        switch self {
        case .nowPlaying:
            return L10n.feedNowPlaying
        case .popular:
            return L10n.feedPopular
        case .topRated:
            return L10n.feedTopRated
        case .upcoming:
            return L10n.feedUpcoming
        }
    }
}

public enum TVShowFeedType: String, CaseIterable, Identifiable {
    case airingToday
    case onTheAir

    public var id: String { rawValue }

    public var localizedTitle: String {
        switch self {
        case .airingToday:
            return L10n.feedAiringToday
        case .onTheAir:
            return L10n.feedOnTheAir
        }
    }
}

public enum ContentFeedType: String, CaseIterable, Identifiable {
    case movies
    case tvShows

    public var id: String { rawValue }

    public var localizedTitle: String {
        switch self {
        case .movies:
            return L10n.feedSearchMovies
        case .tvShows:
            return L10n.feedSearchTv
        }
    }
}

public class MovieFeedViewModel: ObservableObject {
    @Published var state: NowPlayingViewState = .initial
    @Published var searchQuery = ""
    @Published var currentFeedType: MovieFeedType = .nowPlaying
    @Published var searchFilters = SearchFilters()
    @Published var showingFilterSheet = false
    @Published var selectedFilterType: FilterType?

    private var nowPlayingMovies: [Movie] = []
    private var popularMovies: [Movie] = []
    private var topRatedMovies: [Movie] = []
    private var upcomingMovies: [Movie] = []
    private var currentPage: Int = 1
    private let cache: FeedResponseCache

    var hasCachedMovies: Bool {
        !nowPlayingMovies.isEmpty || !popularMovies.isEmpty || !topRatedMovies.isEmpty || !upcomingMovies.isEmpty
    }

    func movies(for feedType: MovieFeedType) -> [Movie] {
        cachedMovies(for: feedType)
    }

    func isLoading(for feedType: MovieFeedType) -> Bool {
        currentFeedType == feedType && state == .loading
    }

    func errorMessage(for feedType: MovieFeedType) -> String? {
        guard currentFeedType == feedType, case .error(let message) = state else { return nil }
        return message
    }

    private var cancellables = Set<AnyCancellable>()
    private let apiService: APIServiceProtocol
    private let additionalParams: AdditionalMovieListParams?
    let analyticsTracker: AnalyticsTracker?

    public convenience init(
        apiService: APIServiceProtocol,
        additionalParams: AdditionalMovieListParams? = nil,
        analyticsTracker: AnalyticsTracker? = nil
    ) {
        self.init(
            apiService: apiService,
            additionalParams: additionalParams,
            analyticsTracker: analyticsTracker,
            cache: .shared
        )
    }

    init(
        apiService: APIServiceProtocol,
        additionalParams: AdditionalMovieListParams? = nil,
        analyticsTracker: AnalyticsTracker? = nil,
        cache: FeedResponseCache
    ) {
        self.apiService = apiService
        self.additionalParams = additionalParams
        self.analyticsTracker = analyticsTracker
        self.cache = cache
        hydrateFromDiskCache()

        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] query in
                guard let self else { return }
                if !query.isEmpty {
                    self.searchMovies(query: query)
                } else if case .error = self.state {
                    // Keep error until cancel/retry.
                } else {
                    self.state = .initial
                }
            }
            .store(in: &cancellables)

        $searchFilters
            .dropFirst()
            .sink { [weak self] _ in
                guard let self, !self.searchQuery.isEmpty else { return }
                self.searchMovies(query: self.searchQuery)
            }
            .store(in: &cancellables)
    }

    @MainActor func updateSelectedFilterToShow(_ filterType: FilterType) {
        selectedFilterType = filterType
        showingFilterSheet = true
    }

    func fetchNowPlayingMovies() {
        currentFeedType = .nowPlaying
        fetchMoviesForCurrentFeedType()
    }

    func switchFeedType(_ feedType: MovieFeedType) {
        currentFeedType = feedType
        currentPage = 1
        fetchMoviesForCurrentFeedType()
    }

    func loadFeed(_ feedType: MovieFeedType) {
        currentFeedType = feedType
        currentPage = 1
        let cached = cachedMovies(for: feedType)
        if !cached.isEmpty {
            state = .loaded(cached)
        }
        fetchMoviesForCurrentFeedType(showLoadingIfEmpty: cached.isEmpty)
    }

    @MainActor
    func refresh() async {
        await fetchMoviesForCurrentFeedTypeAsync(showLoadingIfEmpty: false)
    }

    @MainActor
    func refresh(_ feedType: MovieFeedType) async {
        currentFeedType = feedType
        await fetchMoviesForCurrentFeedTypeAsync(showLoadingIfEmpty: false)
    }

    private func fetchMoviesForCurrentFeedType(showLoadingIfEmpty: Bool = true) {
        Task {
            await fetchMoviesForCurrentFeedTypeAsync(showLoadingIfEmpty: showLoadingIfEmpty)
        }
    }

    @MainActor
    private func fetchMoviesForCurrentFeedTypeAsync(showLoadingIfEmpty: Bool) async {
        let feedType = currentFeedType
        let cached = cachedMovies(for: feedType)
        if showLoadingIfEmpty && cached.isEmpty {
            state = .loading
        } else if !cached.isEmpty, case .initial = state {
            state = .loaded(cached)
        }

        let result: Result<MovieListResponse, Error>
        switch feedType {
        case .nowPlaying:
            result = await apiService.fetchNowPlayingMovies(page: nil, additionalParams: additionalParams)
        case .popular:
            result = await apiService.fetchPopularMovies(page: nil, additionalParams: additionalParams)
        case .topRated:
            result = await apiService.fetchTopRatedMovies(page: nil, additionalParams: additionalParams)
        case .upcoming:
            result = await apiService.fetchUpcomingMovies(page: nil, additionalParams: additionalParams)
        }

        switch result {
        case let .success(response):
            analyticsTracker?.trackPageView(parameters: PageViewParameters(
                screenName: feedType.rawValue,
                screenClass: "MovieFeedPage",
                contentType: "movie_list"
            ))
            storeMovies(response.results, for: feedType)
            cache.saveMovies(response.results, for: feedType)
            currentPage = 1
            state = .loaded(response.results)
        case let .failure(error):
            if !cached.isEmpty {
                state = .loaded(cached)
            } else {
                state = .error(error.localizedDescription)
            }
        }
    }

    func loadCurrentFeedMovies() {
        state = .loaded(cachedMovies(for: currentFeedType))
    }

    func clearSearchAndRetry() {
        searchQuery = ""
        searchFilters = SearchFilters()
        state = .initial
    }

    func cancelSearch() {
        clearSearchAndRetry()
    }

    func retrySearch() {
        if !searchQuery.isEmpty {
            searchMovies(query: searchQuery)
        } else {
            fetchMoviesForCurrentFeedType()
        }
    }

    func searchMovies(query: String) {
        state = .loading

        Task {
            let result = await apiService.searchMovies(
                query: query,
                page: nil,
                filters: searchFilters.hasActiveFilters ? searchFilters : nil
            )
            await MainActor.run {
                switch result {
                case let .success(response):
                    self.state = .searchResults(response.results)
                case let .failure(error):
                    self.state = .error(error.localizedDescription)
                }
            }
        }
    }

    func fetchMoreContentIfNeeded(currentMovieId: Int) {
        guard case .loaded = state,
              currentMovieId == state.movies.last?.id,
              searchQuery.isEmpty else { return }

        Task {
            analyticsTracker?.trackEvent(
                name: "load_more",
                parameters: EventParameters(
                    method: "scroll",
                    success: true,
                    additionalParameters: ["page": currentPage + 1]
                )
            )

            let result: Result<MovieListResponse, Error>
            switch currentFeedType {
            case .nowPlaying:
                result = await apiService.fetchNowPlayingMovies(page: currentPage + 1, additionalParams: additionalParams)
            case .popular:
                result = await apiService.fetchPopularMovies(page: currentPage + 1, additionalParams: additionalParams)
            case .topRated:
                result = await apiService.fetchTopRatedMovies(page: currentPage + 1, additionalParams: additionalParams)
            case .upcoming:
                result = await apiService.fetchUpcomingMovies(page: currentPage + 1, additionalParams: additionalParams)
            }

            await MainActor.run {
                switch result {
                case let .success(response):
                    let combined = cachedMovies(for: currentFeedType) + response.results
                    storeMovies(combined, for: currentFeedType)
                    cache.saveMovies(combined, for: currentFeedType)
                    state = .loaded(combined)
                    currentPage += 1
                case .failure:
                    break
                }
            }
        }
    }

    private func hydrateFromDiskCache() {
        for feedType in MovieFeedType.allCases {
            if let movies = cache.loadMovies(for: feedType) {
                storeMovies(movies, for: feedType)
            }
        }
    }

    private func cachedMovies(for feedType: MovieFeedType) -> [Movie] {
        switch feedType {
        case .nowPlaying: return nowPlayingMovies
        case .popular: return popularMovies
        case .topRated: return topRatedMovies
        case .upcoming: return upcomingMovies
        }
    }

    private func storeMovies(_ movies: [Movie], for feedType: MovieFeedType) {
        switch feedType {
        case .nowPlaying: nowPlayingMovies = movies
        case .popular: popularMovies = movies
        case .topRated: topRatedMovies = movies
        case .upcoming: upcomingMovies = movies
        }
    }
}
