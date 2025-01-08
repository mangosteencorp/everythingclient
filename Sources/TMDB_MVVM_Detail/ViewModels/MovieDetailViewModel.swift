import SwiftUI
import Combine
import TMDB_Shared_Backend
enum MovieDetailState {
    case loading
    case success(Movie)
    case error(String)
}

class MovieDetailViewModel: ObservableObject {
    @Published var state: MovieDetailState = .loading

    private var cancellables = Set<AnyCancellable>()
    private let apiService : TMDBAPIService
    init(apiService: TMDBAPIService) {
        self.apiService = apiService
    }
    func fetchMovieDetail(movieId: Int) {
        state = .loading
        
        Task {
            
            let newState: MovieDetailState
            do {
                let result : Movie = try await apiService.request(.movieDetail(movie: movieId))
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
