import Combine
import CoreFeatures
import SwiftUI
import TMDB_Shared_Backend

public class TVShowFeedViewModel: ObservableObject {
    @Published var state: TVShowViewState = .initial
    @Published var searchQuery = ""
    @Published var currentFeedType: TVShowFeedType = .airingToday
    @Published var searchFilters = SearchFilters()
    @Published var showingFilterSheet = false
    @Published var selectedFilterType: FilterType?

    private var airingTodayShows: [TVShow] = []
    private var onTheAirShows: [TVShow] = []
    private var currentPage: Int = 1
    private var loadingFeedTypes: Set<TVShowFeedType> = []
    private var feedErrors: [TVShowFeedType: String] = [:]
    private var loadTasks: [TVShowFeedType: Task<Void, Never>] = [:]
    private var searchTask: Task<Void, Never>?

    deinit {
        loadTasks.values.forEach { $0.cancel() }
        searchTask?.cancel()
    }

    var hasCachedShows: Bool {
        !airingTodayShows.isEmpty || !onTheAirShows.isEmpty
    }

    func shows(for feedType: TVShowFeedType) -> [TVShow] {
        memoryShows(for: feedType)
    }

    func isLoading(for feedType: TVShowFeedType) -> Bool {
        loadingFeedTypes.contains(feedType)
    }

    func errorMessage(for feedType: TVShowFeedType) -> String? {
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
                    self.searchTVShows(query: query)
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
                self.searchTVShows(query: self.searchQuery)
            }
            .store(in: &cancellables)
    }

    @MainActor func updateSelectedFilterToShow(_ filterType: FilterType) {
        selectedFilterType = filterType
        showingFilterSheet = true
    }

    func fetchAiringTodayTVShows() {
        loadFeed(.airingToday)
    }

    func switchFeedType(_ feedType: TVShowFeedType) {
        loadFeed(feedType)
    }

    /// Single entry point for the views: safe to call on every appearance and on every tab switch.
    /// Already-cached feeds are served from memory and in-flight feeds are not requested twice.
    /// `refresh(_:)` is the deliberate bypass for pull-to-refresh.
    func loadFeed(_ feedType: TVShowFeedType) {
        currentFeedType = feedType
        currentPage = 1
        feedErrors[feedType] = nil

        let cached = memoryShows(for: feedType)
        if !cached.isEmpty {
            state = .loaded(cached)
            return
        }

        loadingFeedTypes.insert(feedType)
        state = .loading
        objectWillChange.send()

        guard loadTasks[feedType] == nil else { return }
        loadTasks[feedType] = Task { @MainActor [weak self] in
            await self?.fetchTVShowsAsync(for: feedType, showLoadingIfEmpty: true)
            self?.loadTasks[feedType] = nil
        }
    }

    /// Stops requests belonging to the previous tab selection.
    func cancelLoads() {
        loadTasks.values.forEach { $0.cancel() }
        loadTasks.removeAll()
    }

    @MainActor
    func refresh() async {
        await fetchTVShowsAsync(for: currentFeedType, showLoadingIfEmpty: false)
    }

    @MainActor
    func refresh(_ feedType: TVShowFeedType) async {
        currentFeedType = feedType
        await fetchTVShowsAsync(for: feedType, showLoadingIfEmpty: false)
    }

    @MainActor
    private func fetchTVShowsAsync(for feedType: TVShowFeedType, showLoadingIfEmpty: Bool) async {
        let cached = memoryShows(for: feedType)
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

        let result: Result<TVShowListResponse, Error>
        switch feedType {
        case .airingToday:
            result = await apiService.fetchAiringTodayTVShows(page: nil, additionalParams: additionalParams)
        case .onTheAir:
            result = await apiService.fetchOnTheAirTVShows(page: nil, additionalParams: additionalParams)
        }

        loadingFeedTypes.remove(feedType)

        // Cancelled by a tab switch or by the page going away: drop the response and leave the feed
        // back at `initial` so the next appearance loads it again instead of showing a stuck spinner.
        guard !Task.isCancelled else {
            if currentFeedType == feedType, state.shows.isEmpty {
                state = .initial
            }
            objectWillChange.send()
            return
        }

        apply(result, for: feedType, cached: cached)
        objectWillChange.send()
    }

    @MainActor
    private func apply(_ result: Result<TVShowListResponse, Error>, for feedType: TVShowFeedType, cached: [TVShow]) {
        switch result {
        case let .success(response):
            analyticsTracker?.trackPageView(parameters: PageViewParameters(
                screenName: feedType.rawValue,
                screenClass: "TVShowFeedPage",
                contentType: "tvshow_list"
            ))
            storeShows(response.results, for: feedType)
            feedErrors[feedType] = nil
            if currentFeedType == feedType {
                currentPage = 1
                state = .loaded(response.results)
            }
        case let .failure(error):
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

    func loadCurrentFeedTVShows() {
        state = .loaded(memoryShows(for: currentFeedType))
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
            searchTVShows(query: searchQuery)
        } else {
            loadFeed(currentFeedType)
        }
    }

    func searchTVShows(query: String) {
        state = .loading

        // Started from a debounced Combine sink, which cannot cancel a Task on its own: fast typing
        // would otherwise leave several searches racing to write the results.
        searchTask?.cancel()
        searchTask = Task { @MainActor [weak self] in
            guard let self else { return }
            let result = await apiService.searchTVShows(
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

    func fetchMoreContentIfNeeded(currentShowId: Int) {
        guard case .loaded = state,
              currentShowId == state.shows.last?.id,
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

            let result: Result<TVShowListResponse, Error>
            switch feedType {
            case .airingToday:
                result = await apiService.fetchAiringTodayTVShows(page: currentPage + 1, additionalParams: additionalParams)
            case .onTheAir:
                result = await apiService.fetchOnTheAirTVShows(page: currentPage + 1, additionalParams: additionalParams)
            }

            await MainActor.run {
                switch result {
                case let .success(response):
                    let combined = memoryShows(for: feedType) + response.results
                    storeShows(combined, for: feedType)
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

    private func memoryShows(for feedType: TVShowFeedType) -> [TVShow] {
        switch feedType {
        case .airingToday: return airingTodayShows
        case .onTheAir: return onTheAirShows
        }
    }

    private func storeShows(_ shows: [TVShow], for feedType: TVShowFeedType) {
        switch feedType {
        case .airingToday: airingTodayShows = shows
        case .onTheAir: onTheAirShows = shows
        }
    }
}

public enum TVShowViewState: Equatable {
    case initial
    case loading
    case loaded([TVShow])
    case searchResults([TVShow])
    case error(String)

    var shows: [TVShow] {
        switch self {
        case .loaded(let shows), .searchResults(let shows):
            return shows
        case .initial, .loading, .error:
            return []
        }
    }

    public static func == (lhs: TVShowViewState, rhs: TVShowViewState) -> Bool {
        switch (lhs, rhs) {
        case (.initial, .initial):
            return true
        case (.loading, .loading):
            return true
        case (.loaded(let lhsShows), .loaded(let rhsShows)):
            return lhsShows.map(\.id) == rhsShows.map(\.id)
        case (.searchResults(let lhsShows), .searchResults(let rhsShows)):
            return lhsShows.map(\.id) == rhsShows.map(\.id)
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }
}

public struct TVShowListResponse: Decodable {
    let page: Int
    public let results: [TVShow]
    let totalPages: Int
    let totalResults: Int

    enum CodingKeys: String, CodingKey {
        case page, results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }

    init(page: Int, results: [TVShow], totalPages: Int, totalResults: Int) {
        self.page = page
        self.results = results
        self.totalPages = totalPages
        self.totalResults = totalResults
    }
}
