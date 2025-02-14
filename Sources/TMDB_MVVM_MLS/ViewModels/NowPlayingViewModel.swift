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

    public init(apiService: APIServiceProtocol) {
        self.apiService = apiService

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
            let result = await self.apiService.fetchNowPlayingMovies(page: nil)
            await MainActor.run {
                switch result {
                case let .success(response):
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
        guard case .loaded = state, // Only fetch more for loaded state, not search results
              currentMovieId == state.movies.last?.id,
              searchQuery.isEmpty else { return }

        Task {
            let result = await self.apiService.fetchNowPlayingMovies(page: currentPage + 1)
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
