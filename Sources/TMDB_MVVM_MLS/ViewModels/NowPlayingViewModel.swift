import Combine
import CoreFeatures
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
                    self.analyticsTracker?.trackPageView(parameters: PageViewParameters(
                        screenName: "now_playing",
                        screenClass: "NowPlayingPage",
                        contentType: "movie_list"
                    ))
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
            self.analyticsTracker?.trackEvent(
                name: "load_more",
                parameters: EventParameters(
                    method: "scroll",
                    success: true,
                    additionalParameters: ["page": currentPage + 1]
                )
            )
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
