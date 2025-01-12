import SwiftUI
import Combine
import TMDB_Shared_Backend
protocol APIServiceProtocol {
    func fetchNowPlayingMovies(page: Int?) async -> Result<NowPlayingResponse, Error>
}
extension TMDBAPIService: APIServiceProtocol {
    func fetchNowPlayingMovies(page: Int?) async -> Result<NowPlayingResponse, any Error> {
        let result: Result<NowPlayingResponse, TMDBAPIError> = await request(.nowPlaying(page: page))
        // Map TMDBAPIError to Error
        switch result {
        case .success(let response):
            return .success(response)
        case .failure(let error):
            return .failure(error as Error)
        }
    }
}

class NowPlayingViewModel: ObservableObject {
    @Published var movies: [Movie] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    var currentPage: Int = 1
    
    private var cancellables = Set<AnyCancellable>()
    private let apiService: APIServiceProtocol
    init(apiService: APIServiceProtocol) {
        self.apiService = apiService
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

