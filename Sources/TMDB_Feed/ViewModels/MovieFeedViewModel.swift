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
    private var loadingFeedTypes: Set<MovieFeedType> = []
    private var feedErrors: [MovieFeedType: String] = [:]

    var hasCachedMovies: Bool {
        !nowPlayingMovies.isEmpty || !popularMovies.isEmpty || !topRatedMovies.isEmpty || !upcomingMovies.isEmpty
    }

    func movies(for feedType: MovieFeedType) -> [Movie] {
        memoryMovies(for: feedType)
    }

    func isLoading(for feedType: MovieFeedType) -> Bool {
        loadingFeedTypes.contains(feedType)
    }

    func errorMessage(for feedType: MovieFeedType) -> String? {
        feedErrors[feedType]
    }

    private var cancellables = Set<AnyCancellable>()
    private let apiService: APIServiceProtocol
    private let additionalParams: AdditionalMovieListParams?
    let analyticsTracker: AnalyticsTracker?

    public init(
        apiService: APIServiceProtocol,
        additionalParams: AdditionalMovieListParams? = nil,
        analyticsTracker: AnalyticsTracker? = nil
    ) {
        self.apiService = apiService
        self.additionalParams = additionalParams
        self.analyticsTracker = analyticsTracker

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
        loadFeed(.nowPlaying)
    }

    func switchFeedType(_ feedType: MovieFeedType) {
        loadFeed(feedType)
    }

    func loadFeed(_ feedType: MovieFeedType) {
        currentFeedType = feedType
        currentPage = 1
        let cached = memoryMovies(for: feedType)
        if !cached.isEmpty {
            state = .loaded(cached)
            feedErrors[feedType] = nil
        } else {
            guard !loadingFeedTypes.contains(feedType) else { return }
            loadingFeedTypes.insert(feedType)
            feedErrors[feedType] = nil
            state = .loading
            objectWillChange.send()
        }
        fetchMovies(for: feedType, showLoadingIfEmpty: cached.isEmpty)
    }

    @MainActor
    func refresh() async {
        await fetchMoviesAsync(for: currentFeedType, showLoadingIfEmpty: false)
    }

    @MainActor
    func refresh(_ feedType: MovieFeedType) async {
        currentFeedType = feedType
        await fetchMoviesAsync(for: feedType, showLoadingIfEmpty: false)
    }

    private func fetchMovies(for feedType: MovieFeedType, showLoadingIfEmpty: Bool = true) {
        Task { @MainActor in
            await fetchMoviesAsync(for: feedType, showLoadingIfEmpty: showLoadingIfEmpty)
        }
    }

    @MainActor
    private func fetchMoviesAsync(for feedType: MovieFeedType, showLoadingIfEmpty: Bool) async {
        let cached = memoryMovies(for: feedType)
        if showLoadingIfEmpty && cached.isEmpty {
            loadingFeedTypes.insert(feedType)
            feedErrors[feedType] = nil
            if currentFeedType == feedType {
                state = .loading
            }
            objectWillChange.send()
        } else if !cached.isEmpty, currentFeedType == feedType, case .initial = state {
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

        loadingFeedTypes.remove(feedType)

        switch result {
        case let .success(response):
            analyticsTracker?.trackPageView(parameters: PageViewParameters(
                screenName: feedType.rawValue,
                screenClass: "MovieFeedPage",
                contentType: "movie_list"
            ))
            storeMovies(response.results, for: feedType)
            feedErrors[feedType] = nil
            if currentFeedType == feedType {
                currentPage = 1
                state = .loaded(response.results)
            }
        case let .failure(error):
            // URLSession cache may already have satisfied the request when enabled;
            // otherwise fall back to in-memory list from this session.
            if !cached.isEmpty {
                if currentFeedType == feedType {
                    state = .loaded(cached)
                }
            } else {
                feedErrors[feedType] = error.localizedDescription
                if currentFeedType == feedType {
                    state = .error(error.localizedDescription)
                }
            }
        }
        objectWillChange.send()
    }

    func loadCurrentFeedMovies() {
        state = .loaded(memoryMovies(for: currentFeedType))
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
            fetchMovies(for: currentFeedType)
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

        let feedType = currentFeedType
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
            switch feedType {
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
                    let combined = memoryMovies(for: feedType) + response.results
                    storeMovies(combined, for: feedType)
                    if currentFeedType == feedType {
                        state = .loaded(combined)
                        currentPage += 1
                    }
                case .failure:
                    break
                }
            }
        }
    }

    private func memoryMovies(for feedType: MovieFeedType) -> [Movie] {
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
