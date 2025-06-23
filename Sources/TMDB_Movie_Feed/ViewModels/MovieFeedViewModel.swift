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

public class MovieFeedViewModel: ObservableObject {
    @Published var state: NowPlayingViewState = .initial
    @Published var searchQuery = ""
    @Published var currentFeedType: MovieFeedType = .nowPlaying
    @Published var searchFilters = SearchFilters()

    private var nowPlayingMovies: [Movie] = []
    private var popularMovies: [Movie] = []
    private var topRatedMovies: [Movie] = []
    private var upcomingMovies: [Movie] = []
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
                    self.loadCurrentFeedMovies()
                }
            }
            .store(in: &cancellables)
        
        // Watch for filter changes and re-search if there's an active search
        $searchFilters
            .sink { [weak self] _ in
                if let self = self, !self.searchQuery.isEmpty {
                    self.searchMovies(query: self.searchQuery)
                }
            }
            .store(in: &cancellables)
    }

    func fetchNowPlayingMovies() {
        currentFeedType = .nowPlaying
        fetchMoviesForCurrentFeedType()
    }
    
    func switchFeedType(_ feedType: MovieFeedType) {
        currentFeedType = feedType
        fetchMoviesForCurrentFeedType()
    }
    
    private func fetchMoviesForCurrentFeedType() {
        state = .loading
        
        Task {
            let result: Result<NowPlayingResponse, Error>
            
            switch currentFeedType {
            case .nowPlaying:
                result = await apiService.fetchNowPlayingMovies(
                    page: nil,
                    additionalParams: additionalParams
                )
            case .popular:
                result = await apiService.fetchPopularMovies(
                    page: nil,
                    additionalParams: additionalParams
                )
            case .topRated:
                result = await apiService.fetchTopRatedMovies(
                    page: nil,
                    additionalParams: additionalParams
                )
            case .upcoming:
                result = await apiService.fetchUpcomingMovies(
                    page: nil,
                    additionalParams: additionalParams
                )
            }
            
            await MainActor.run {
                switch result {
                case let .success(response):
                    self.analyticsTracker?.trackPageView(parameters: PageViewParameters(
                        screenName: currentFeedType.rawValue,
                        screenClass: "MovieFeedPage",
                        contentType: "movie_list"
                    ))
                    
                    // Store movies based on feed type
                    switch currentFeedType {
                    case .nowPlaying:
                        self.nowPlayingMovies = response.results
                    case .popular:
                        self.popularMovies = response.results
                    case .topRated:
                        self.topRatedMovies = response.results
                    case .upcoming:
                        self.upcomingMovies = response.results
                    }
                    
                    self.state = .loaded(response.results)
                case let .failure(error):
                    self.state = .error(error.localizedDescription)
                }
            }
        }
    }
    
    private func loadCurrentFeedMovies() {
        let movies: [Movie]
        switch currentFeedType {
        case .nowPlaying:
            movies = nowPlayingMovies
        case .popular:
            movies = popularMovies
        case .topRated:
            movies = topRatedMovies
        case .upcoming:
            movies = upcomingMovies
        }
        state = .loaded(movies)
    }

    private func searchMovies(query: String) {
        if case .loaded(let movies) = state {
            state = .searchResults(movies)
        }

        Task {
            let result = await apiService.searchMovies(query: query, page: nil, filters: searchFilters.hasActiveFilters ? searchFilters : nil)
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
            
            switch currentFeedType {
            case .nowPlaying:
                result = await apiService.fetchNowPlayingMovies(
                    page: currentPage + 1,
                    additionalParams: additionalParams
                )
            case .popular:
                result = await apiService.fetchPopularMovies(
                    page: currentPage + 1,
                    additionalParams: additionalParams
                )
            case .topRated:
                result = await apiService.fetchTopRatedMovies(
                    page: currentPage + 1,
                    additionalParams: additionalParams
                )
            case .upcoming:
                result = await apiService.fetchUpcomingMovies(
                    page: currentPage + 1,
                    additionalParams: additionalParams
                )
            }
            
            await MainActor.run {
                switch result {
                case let .success(response):
                    // Append to the appropriate array based on feed type
                    switch currentFeedType {
                    case .nowPlaying:
                        self.nowPlayingMovies.append(contentsOf: response.results)
                        self.state = .loaded(self.nowPlayingMovies)
                    case .popular:
                        self.popularMovies.append(contentsOf: response.results)
                        self.state = .loaded(self.popularMovies)
                    case .topRated:
                        self.topRatedMovies.append(contentsOf: response.results)
                        self.state = .loaded(self.topRatedMovies)
                    case .upcoming:
                        self.upcomingMovies.append(contentsOf: response.results)
                        self.state = .loaded(self.upcomingMovies)
                    }
                    self.currentPage += 1
                case .failure:
                    break
                }
            }
        }
    }
}
