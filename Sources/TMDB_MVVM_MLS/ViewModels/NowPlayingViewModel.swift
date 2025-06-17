import Combine
import CoreFeatures
import SwiftUI
import TMDB_Shared_Backend

public enum MovieFeedType: String, CaseIterable, Identifiable {
    case nowPlaying = "Now Playing"
    case popular = "Popular"
    case topRated = "Top Rated"
    case upcoming = "Upcoming"

    public var id: String { rawValue }
}

public class MovieFeedViewModel: ObservableObject {
    @Published var state: NowPlayingViewState = .initial
    @Published var searchQuery = ""
    @Published var feedType: MovieFeedType = .nowPlaying {
        didSet { fetchMovies() }
    }

    private var movies: [Movie] = []
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
                    self.state = .loaded(self.movies)
                }
            }
            .store(in: &cancellables)
    }

    func fetchMovies() {
        state = .loading
        Task {
            let result: Result<NowPlayingResponse, Error>
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
            await MainActor.run {
                switch result {
                case let .success(response):
                    self.analyticsTracker?.trackPageView(parameters: PageViewParameters(
                        screenName: self.feedType.rawValue.lowercased().replacingOccurrences(of: " ", with: "_"),
                        screenClass: "MovieFeedListPage",
                        contentType: "movie_list"
                    ))
                    self.movies = response.results
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
            let result: Result<NowPlayingResponse, Error>
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
                    self.movies.append(contentsOf: response.results)
                    self.state = .loaded(self.movies)
                    self.currentPage += 1
                case .failure:
                    break
                }
            }
        }
    }
}
