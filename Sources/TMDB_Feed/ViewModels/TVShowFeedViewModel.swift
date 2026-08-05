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

    var hasCachedShows: Bool {
        !airingTodayShows.isEmpty || !onTheAirShows.isEmpty
    }

    func shows(for feedType: TVShowFeedType) -> [TVShow] {
        memoryShows(for: feedType)
    }

    func isLoading(for feedType: TVShowFeedType) -> Bool {
        currentFeedType == feedType && state == .loading
    }

    func errorMessage(for feedType: TVShowFeedType) -> String? {
        guard currentFeedType == feedType, case .error(let message) = state else { return nil }
        return message
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
        currentFeedType = .airingToday
        fetchTVShowsForCurrentFeedType()
    }

    func switchFeedType(_ feedType: TVShowFeedType) {
        currentFeedType = feedType
        currentPage = 1
        fetchTVShowsForCurrentFeedType()
    }

    func loadFeed(_ feedType: TVShowFeedType) {
        currentFeedType = feedType
        currentPage = 1
        let cached = memoryShows(for: feedType)
        if !cached.isEmpty {
            state = .loaded(cached)
        }
        fetchTVShowsForCurrentFeedType(showLoadingIfEmpty: cached.isEmpty)
    }

    @MainActor
    func refresh() async {
        await fetchTVShowsForCurrentFeedTypeAsync(showLoadingIfEmpty: false)
    }

    @MainActor
    func refresh(_ feedType: TVShowFeedType) async {
        currentFeedType = feedType
        await fetchTVShowsForCurrentFeedTypeAsync(showLoadingIfEmpty: false)
    }

    private func fetchTVShowsForCurrentFeedType(showLoadingIfEmpty: Bool = true) {
        Task {
            await fetchTVShowsForCurrentFeedTypeAsync(showLoadingIfEmpty: showLoadingIfEmpty)
        }
    }

    @MainActor
    private func fetchTVShowsForCurrentFeedTypeAsync(showLoadingIfEmpty: Bool) async {
        let feedType = currentFeedType
        let cached = memoryShows(for: feedType)
        if showLoadingIfEmpty && cached.isEmpty {
            state = .loading
        } else if !cached.isEmpty, case .initial = state {
            state = .loaded(cached)
        }

        let result: Result<TVShowListResponse, Error>
        switch feedType {
        case .airingToday:
            result = await apiService.fetchAiringTodayTVShows(page: nil, additionalParams: additionalParams)
        case .onTheAir:
            result = await apiService.fetchOnTheAirTVShows(page: nil, additionalParams: additionalParams)
        }

        switch result {
        case let .success(response):
            analyticsTracker?.trackPageView(parameters: PageViewParameters(
                screenName: feedType.rawValue,
                screenClass: "TVShowFeedPage",
                contentType: "tvshow_list"
            ))
            storeShows(response.results, for: feedType)
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
            fetchTVShowsForCurrentFeedType()
        }
    }

    func searchTVShows(query: String) {
        state = .loading

        Task {
            let result = await apiService.searchTVShows(
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

    func fetchMoreContentIfNeeded(currentShowId: Int) {
        guard case .loaded = state,
              currentShowId == state.shows.last?.id,
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

            let result: Result<TVShowListResponse, Error>
            switch currentFeedType {
            case .airingToday:
                result = await apiService.fetchAiringTodayTVShows(page: currentPage + 1, additionalParams: additionalParams)
            case .onTheAir:
                result = await apiService.fetchOnTheAirTVShows(page: currentPage + 1, additionalParams: additionalParams)
            }

            await MainActor.run {
                switch result {
                case let .success(response):
                    let combined = memoryShows(for: currentFeedType) + response.results
                    storeShows(combined, for: currentFeedType)
                    state = .loaded(combined)
                    currentPage += 1
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
