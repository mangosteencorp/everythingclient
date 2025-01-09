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
    @MainActor
    func fetchMovieDetail(movieId: Int) async {
        state = .loading
        let newState: MovieCastingState
        do {
            let result : MovieCredits = try await apiService.request(.credits(movie: movieId))
            state = .success(result)
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
