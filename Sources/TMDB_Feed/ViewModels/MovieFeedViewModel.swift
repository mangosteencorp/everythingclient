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
    private var loadTasks: [MovieFeedType: Task<Void, Never>] = [:]
    private var searchTask: Task<Void, Never>?

    deinit {
        loadTasks.values.forEach { $0.cancel() }
        searchTask?.cancel()
    }

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

    /// Single entry point for the views: safe to call on every appearance and on every tab switch.
    /// Already-cached feeds are served from memory and in-flight feeds are not requested twice, so
    /// callers no longer need their own `isEmpty` / `isLoading` checks. `refresh(_:)` is the
    /// deliberate bypass for pull-to-refresh.
    func loadFeed(_ feedType: MovieFeedType) {
        currentFeedType = feedType
        currentPage = 1
        feedErrors[feedType] = nil

        let cached = memoryMovies(for: feedType)
        if !cached.isEmpty {
            state = .loaded(cached)
            return
        }

        loadingFeedTypes.insert(feedType)
        state = .loading
        objectWillChange.send()

        guard loadTasks[feedType] == nil else { return }
        loadTasks[feedType] = Task { @MainActor [weak self] in
            await self?.fetchMoviesAsync(for: feedType, showLoadingIfEmpty: true)
            self?.loadTasks[feedType] = nil
        }
    }

    /// Stops feeds that are still loading. The preloads started by the feed page belong to no view,
    /// so `.task` cancellation cannot reach them.
    func cancelLoads() {
        loadTasks.values.forEach { $0.cancel() }
        loadTasks.removeAll()
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

        // Cancelled by a tab switch or by the page going away: drop the response and leave the feed
        // back at `initial` so the next appearance loads it again instead of showing a stuck spinner.
        guard !Task.isCancelled else {
            if currentFeedType == feedType, state.movies.isEmpty {
                state = .initial
            }
            objectWillChange.send()
            return
        }

        apply(result, for: feedType, cached: cached)
        objectWillChange.send()
    }

    @MainActor
    private func apply(_ result: Result<MovieListResponse, Error>, for feedType: MovieFeedType, cached: [Movie]) {
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
            loadFeed(currentFeedType)
        }
    }

    func searchMovies(query: String) {
        state = .loading

        // Started from a debounced Combine sink, which cannot cancel a Task on its own: fast typing
        // would otherwise leave several searches racing to write the results.
        searchTask?.cancel()
        searchTask = Task { @MainActor [weak self] in
            guard let self else { return }
            let result = await apiService.searchMovies(
                query: query,
                page: nil,
                filters: searchFilters.hasActiveFilters ? searchFilters : nil
            )
            guard !Task.isCancelled else { return }
            switch result {
            case let .success(response):
                self.state = .searchResults(response.results)
            case let .failure(error):
                self.state = .error(error.localizedDescription)
            }
            self.searchTask = nil
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
