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

    // Computed property to check if we have any cached TV shows
    var hasCachedShows: Bool {
        return !airingTodayShows.isEmpty || !onTheAirShows.isEmpty
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
                if !query.isEmpty {
                    self?.searchTVShows(query: query)
                } else if let self = self {
                    self.loadCurrentFeedTVShows()
                }
            }
            .store(in: &cancellables)

        // Watch for filter changes and re-search if there's an active search
        $searchFilters
            .sink { [weak self] _ in
                if let self = self, !self.searchQuery.isEmpty {
                    self.searchTVShows(query: self.searchQuery)
                }
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
        fetchTVShowsForCurrentFeedType()
    }

    private func fetchTVShowsForCurrentFeedType() {
        state = .loading

        Task {
            let result: Result<TVShowListResponse, Error>

            switch currentFeedType {
            case .airingToday:
                result = await apiService.fetchAiringTodayTVShows(
                    page: nil,
                    additionalParams: additionalParams
                )
            case .onTheAir:
                result = await apiService.fetchOnTheAirTVShows(
                    page: nil,
                    additionalParams: additionalParams
                )
            }

            await MainActor.run {
                switch result {
                case let .success(response):
                    self.analyticsTracker?.trackPageView(parameters: PageViewParameters(
                        screenName: currentFeedType.rawValue,
                        screenClass: "TVShowFeedPage",
                        contentType: "tvshow_list"
                    ))

                    // Store shows based on feed type
                    switch currentFeedType {
                    case .airingToday:
                        self.airingTodayShows = response.results
                    case .onTheAir:
                        self.onTheAirShows = response.results
                    }

                    self.state = .loaded(response.results)
                case let .failure(error):
                    self.state = .error(error.localizedDescription)
                }
            }
        }
    }

    func loadCurrentFeedTVShows() {
        let shows: [TVShow]
        switch currentFeedType {
        case .airingToday:
            shows = airingTodayShows
        case .onTheAir:
            shows = onTheAirShows
        }
        state = .loaded(shows)
    }

    private func searchTVShows(query: String) {
        if case .loaded(let shows) = state {
            state = .searchResults(shows)
        }

        Task {
            let result = await apiService.searchTVShows(query: query, page: nil, filters: searchFilters.hasActiveFilters ? searchFilters : nil)
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
            self.analyticsTracker?.trackEvent(
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
                result = await apiService.fetchAiringTodayTVShows(
                    page: currentPage + 1,
                    additionalParams: additionalParams
                )
            case .onTheAir:
                result = await apiService.fetchOnTheAirTVShows(
                    page: currentPage + 1,
                    additionalParams: additionalParams
                )
            }

            await MainActor.run {
                switch result {
                case let .success(response):
                    // Append to the appropriate array based on feed type
                    switch currentFeedType {
                    case .airingToday:
                        self.airingTodayShows.append(contentsOf: response.results)
                        self.state = .loaded(self.airingTodayShows)
                    case .onTheAir:
                        self.onTheAirShows.append(contentsOf: response.results)
                        self.state = .loaded(self.onTheAirShows)
                    }
                    self.currentPage += 1
                case .failure:
                    break
                }
            }
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
}