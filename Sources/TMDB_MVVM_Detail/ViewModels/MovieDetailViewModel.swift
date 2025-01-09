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
    
    func fetchMovieDetail(movieId: Int)  {
        state = .loading
        Task{
            let result : Result<Movie,TMDBAPIError> = await apiService.request(.movieDetail(movie: movieId))
            DispatchQueue.main.async {
                switch result {
                case .success(let movieDetail):
                    self.state = .success(movieDetail)
                case .failure(let error):
                    self.state = .error(error.localizedDescription)
                }
            }
        }
    }
}
