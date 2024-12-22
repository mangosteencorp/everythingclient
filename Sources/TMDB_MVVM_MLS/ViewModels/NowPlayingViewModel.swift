import SwiftUI
import Combine


class NowPlayingViewModel: ObservableObject {
    @Published var movies: [Movie] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    var currentPage: Int = 1
    
    private var cancellables = Set<AnyCancellable>()
    private let apiService = APIService.shared
    
    func fetchNowPlayingMovies() {
        isLoading = true
        errorMessage = nil
        
        Task {
            let result = await self.apiService.fetchNowPlayingMovies()
            DispatchQueue.main.async {
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
        if currentMovieId == movies.last?.id {
            Task {
                let result = await self.apiService.fetchNowPlayingMovies(page: currentPage+1)
                await MainActor.run {
                    switch result {
                    case .success(let response):
                        self.movies.append(contentsOf: response.results)
                        self.currentPage += 1
                    case .failure:
                        break
                    }
                }
            }
            
        }
    }
}

