import SwiftUI
import Combine
import TMDB_Shared_Backend
enum MovieCastingState {
    case loading
    case success(MovieCredits)
    case error(String)
}

class MovieCastingViewModel: ObservableObject {
    @Published var state: MovieCastingState = .loading

    private var cancellables = Set<AnyCancellable>()
    private let apiService : TMDBAPIService
    init(apiService: TMDBAPIService) {
        self.apiService = apiService
    }
    func fetchMovieDetail(movieId: Int) {
        state = .loading
        
        Task {
            
            let newState: MovieCastingState
            do {
                let result : MovieCredits = try await apiService.request(.credits(movie: movieId))
                newState = .success(result)
            } catch {
                newState = .error(error.localizedDescription)
            }
            DispatchQueue.main.async {
                self.state = newState
            }
        }
    }
}
