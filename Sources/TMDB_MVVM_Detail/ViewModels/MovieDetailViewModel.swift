import Combine
import SwiftUI
import TMDB_Shared_Backend

enum MovieDetailState {
    case loading
    case success(Movie)
    case error(String)
}

class MovieDetailViewModel: ObservableObject {
    @Published var state: MovieDetailState = .loading

    private var cancellables = Set<AnyCancellable>()
    private let apiService: TMDBAPIService
    init(apiService: TMDBAPIService) {
        self.apiService = apiService
    }

    func fetchMovieDetail(movieId: Int) {
        state = .loading
        Task {
            let result: Result<Movie, TMDBAPIError> = await apiService.request(.movieDetail(movie: movieId))
            DispatchQueue.main.async {
                switch result {
                case let .success(movieDetail):
                    self.state = .success(movieDetail)
                case let .failure(error):
                    self.state = .error(error.localizedDescription)
                }
            }
        }
    }
}
