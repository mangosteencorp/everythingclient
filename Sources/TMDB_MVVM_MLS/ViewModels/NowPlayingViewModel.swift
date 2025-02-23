import Combine
import SwiftUI
import TMDB_Shared_Backend

public class NowPlayingViewModel: ObservableObject {
    @Published var state: NowPlayingViewState = .initial
    @Published var searchQuery = ""

    private var nowPlayingMovies: [Movie] = []
    private var currentPage: Int = 1
    private var cancellables = Set<AnyCancellable>()
    private let apiService: APIServiceProtocol
    private let additionalParams: AdditionalMovieListParams?
    let analyticTracker: MovieFeedAnalyticsTrackerProtocol?
    public init(
        apiService: APIServiceProtocol,
        additionalParams: AdditionalMovieListParams? = nil,
        analyticTracker: MovieFeedAnalyticsTrackerProtocol? = nil
    ) {
        self.apiService = apiService
        self.additionalParams = additionalParams
        self.analyticTracker = analyticTracker
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] query in
                if !query.isEmpty {
                    self?.searchMovies(query: query)
                } else if let self = self {
                    self.state = .loaded(self.nowPlayingMovies)
                }
            }
            .store(in: &cancellables)
    }

    func fetchNowPlayingMovies() {
        state = .loading

        Task {
            let result = await self.apiService.fetchNowPlayingMovies(
                page: nil,
                additionalParams: additionalParams
            )
            await MainActor.run {
                switch result {
                case let .success(response):
                    self.analyticTracker?.trackAnalyticEvent(.pageView)
                    self.nowPlayingMovies = response.results
                    self.state = .loaded(response.results)
                case let .failure(error):
                    self.state = .error(error.localizedDescription)
                }
            }
        }
    }

    private func searchMovies(query: String) {
        state = .loading

        Task {
            let result = await apiService.searchMovies(query: query, page: nil)
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
            self.analyticTracker?.trackAnalyticEvent(.loadMore)
            let result = await self.apiService.fetchNowPlayingMovies(
                page: currentPage + 1,
                additionalParams: additionalParams
            )
            await MainActor.run {
                switch result {
                case let .success(response):
                    self.nowPlayingMovies.append(contentsOf: response.results)
                    self.state = .loaded(self.nowPlayingMovies)
                    self.currentPage += 1
                case .failure:
                    break
                }
            }
        }
    }
}
