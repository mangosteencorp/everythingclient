import SwiftUI
import Combine
import TMDB_Shared_Backend
enum MovieCastingState {
    case loading
    case success(MovieCredits)
    case error(String)
}

class MovieCastingViewModel: ObservableObject {
    @Published var state: MovieCastingState
    
    private var cancellables = Set<AnyCancellable>()
    private let apiService : TMDBAPIService
    init(apiService: TMDBAPIService) {
        self.apiService = apiService
        state = .loading
    }
    
    func fetchMovieCredits(movieId: Int) {
        state = .loading
        Task{
            let result : Result<MovieCredits,TMDBAPIError> = await apiService.request(.credits(movie: movieId))
            DispatchQueue.main.async {
                switch result {
                case .success(let credits):
                    self.state = .success(credits)
                case .failure(let error):
                    self.state = .error(error.localizedDescription)
                    
                }
            }
        }
    }
}
