import SwiftUI
import Combine
import TMDB_Shared_Backend

class NowPlayingViewModel: ObservableObject {
    @Published var movies: [Movie] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchQuery = ""
    
    private var nowPlayingMovies: [Movie] = [] // Store original now playing movies
    private var currentPage: Int = 1
    private var cancellables = Set<AnyCancellable>()
    private let apiService: APIServiceProtocol
    
    init(apiService: APIServiceProtocol) {
        self.apiService = apiService
        
        // Add search debounce
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] query in
                if !query.isEmpty {
                    self?.searchMovies(query: query)
                } else {
                    // Restore original now playing movies when search is empty
                    self?.movies = self?.nowPlayingMovies ?? []
                }
            }
            .store(in: &cancellables)
    }
    
    func fetchNowPlayingMovies() {
        isLoading = true
        errorMessage = nil
        
        Task {
            let result = await self.apiService.fetchNowPlayingMovies(page: nil)
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let response):
                    self.movies = response.results
                    self.nowPlayingMovies = response.results // Store original results
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func searchMovies(query: String) {
        isLoading = true
        errorMessage = nil
        
        Task {
            let result = await apiService.searchMovies(query: query, page: nil)
            await MainActor.run {
                self.isLoading = false
                switch result {
                case .success(let response):
                    self.movies = response.results
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func fetchMoreContentIfNeeded(currentMovieId: Int) {
        guard searchQuery.isEmpty else { return } // Don't load more while searching
        if currentMovieId == movies.last?.id {
            Task {
                let result = await self.apiService.fetchNowPlayingMovies(page: currentPage+1)
                await MainActor.run {
                    switch result {
                    case .success(let response):
                        self.movies.append(contentsOf: response.results)
                        self.nowPlayingMovies = self.movies // Update stored results
                        self.currentPage += 1
                    case .failure:
                        break
                    }
                }
            }
        }
    }
}

