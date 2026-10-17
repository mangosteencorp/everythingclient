import CoreFeatures
import SwiftUI
import TMDB_Shared_Backend
import TMDB_Shared_UI

/// One TV feed; see `MovieFeedViewModel`.
public class TVShowFeedViewModel: ObservableObject {
    public let feedType: TVShowFeedType
    @Published private(set) var state: FeedState<TVShow> = .idle

    /// Last page fetched; `state` holds every page up to it.
    private var page = 1
    private var loadTask: Task<Void, Never>?
    private var loadMoreTask: Task<Void, Never>?

    private let apiService: APIServiceProtocol
    private let additionalParams: AdditionalMovieListParams?
    let analyticsTracker: AnalyticsTracker?

    deinit {
        loadTask?.cancel()
        loadMoreTask?.cancel()
    }

    public init(
        feedType: TVShowFeedType,
        apiService: APIServiceProtocol,
        additionalParams: AdditionalMovieListParams? = nil,
        analyticsTracker: AnalyticsTracker? = nil
    ) {
        self.feedType = feedType
        self.apiService = apiService
        self.additionalParams = additionalParams
        self.analyticsTracker = analyticsTracker
    }

    /// Safe to call on every appearance; see `MovieFeedViewModel.load()`.
    func load() {
        guard state.items.isEmpty, loadTask == nil else { return }
        state = .loading
        loadTask = Task { @MainActor [weak self] in
            await self?.fetchFirstPage()
            self?.loadTask = nil
        }
    }

    @MainActor
    func refresh() async {
        await fetchFirstPage()
    }

    @MainActor
    private func fetchFirstPage() async {
        let result = await fetch(page: nil)

        // Cancelled by the page going away: drop the response, so the next appearance loads
        // again instead of showing a stuck spinner.
        guard !Task.isCancelled else {
            if case .loading = state { state = .idle }
            return
        }

        switch result {
        case let .success(response):
            analyticsTracker?.trackPageView(parameters: PageViewParameters(
                screenName: feedType.rawValue,
                screenClass: "TVShowFeedPage",
                contentType: "tvshow_list"
            ))
            // A load-more still in flight would append its stale page onto the fresh page 1.
            loadMoreTask?.cancel()
            loadMoreTask = nil
            state = .loaded(response.results)
            page = 1
        case let .failure(error):
            if state.items.isEmpty {
                state = .error(message: error.localizedDescription)
            }
        }
    }

    func fetchMoreContentIfNeeded(currentShowId: Int) {
        guard case let .loaded(shows) = state,
              currentShowId == shows.last?.id,
              loadMoreTask == nil else { return }

        let nextPage = page + 1
        loadMoreTask = Task { @MainActor [weak self] in
            guard let self else { return }
            analyticsTracker?.trackEvent(
                name: "load_more",
                parameters: EventParameters(
                    method: "scroll",
                    success: true,
                    additionalParameters: ["page": nextPage]
                )
            )

            let result = await fetch(page: nextPage)

            // Cancelled by a refresh, which already replaced the feed and owns the task slot.
            guard !Task.isCancelled else { return }
            loadMoreTask = nil

            guard case let .success(response) = result else { return }
            state = .loaded(state.items.appendingUnique(response.results))
            page = nextPage
        }
    }

    private func fetch(page: Int?) async -> Result<TVShowListResponse, Error> {
        switch feedType {
        case .airingToday:
            return await apiService.fetchAiringTodayTVShows(page: page, additionalParams: additionalParams)
        case .onTheAir:
            return await apiService.fetchOnTheAirTVShows(page: page, additionalParams: additionalParams)
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
