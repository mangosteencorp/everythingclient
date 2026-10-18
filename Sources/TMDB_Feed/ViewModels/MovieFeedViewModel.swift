import CoreFeatures
import SwiftUI
import TMDB_Shared_Backend
import TMDB_Shared_UI

/// One movie feed. A host showing several feeds gives each its own view model, so their
/// lists, pages and in-flight requests never touch each other.
public class MovieFeedViewModel: ObservableObject {
    public let feedType: MovieFeedType
    @Published private(set) var state: FeedState<Movie> = .idle

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
        feedType: MovieFeedType,
        apiService: APIServiceProtocol,
        additionalParams: AdditionalMovieListParams? = nil,
        analyticsTracker: AnalyticsTracker? = nil
    ) {
        self.feedType = feedType
        self.apiService = apiService
        self.additionalParams = additionalParams
        self.analyticsTracker = analyticsTracker
    }

    /// Safe to call on every appearance: a loaded feed stays as it is and an in-flight request
    /// is not sent twice. `refresh()` is the deliberate bypass for pull-to-refresh.
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
                screenClass: "MovieFeedPage",
                contentType: "movie_list"
            ))
            // A load-more still in flight would append its stale page onto the fresh page 1.
            loadMoreTask?.cancel()
            loadMoreTask = nil
            state = .loaded(response.results)
            page = 1
        case let .failure(error):
            // URLSession cache may already have satisfied the request when enabled;
            // otherwise keep what this session already showed.
            if state.items.isEmpty {
                state = .error(message: error.localizedDescription)
            }
        }
    }

    func fetchMoreContentIfNeeded(currentMovieId: Int) {
        guard case let .loaded(movies) = state,
              currentMovieId == movies.last?.id,
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

    private func fetch(page: Int?) async -> Result<MovieListResponse, Error> {
        switch feedType {
        case .nowPlaying:
            return await apiService.fetchNowPlayingMovies(page: page, additionalParams: additionalParams)
        case .popular:
            return await apiService.fetchPopularMovies(page: page, additionalParams: additionalParams)
        case .topRated:
            return await apiService.fetchTopRatedMovies(page: page, additionalParams: additionalParams)
        case .upcoming:
            return await apiService.fetchUpcomingMovies(page: page, additionalParams: additionalParams)
        }
    }
}
