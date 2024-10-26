import SwiftUI
import Combine

enum MovieCastingState {
    case loading
    case success(MovieCredits)
    case error(String)
}

class MovieCastingViewModel: ObservableObject {
    @Published var state: MovieCastingState = .loading

    private var cancellables = Set<AnyCancellable>()
    private let apiService = APIService.shared
    
    func fetchMovieDetail(movieId: Int) {
        state = .loading
        
        Task {
            let result: Result<MovieCredits, APIService.APIError> = await self.apiService.fetch(endpoint: .credits(movie: movieId), params: nil)
            
            DispatchQueue.main.async {
                switch result {
                case .success(let movieCredits):
                    self.state = .success(movieCredits)
                case .failure(let error):
                    self.state = .error(error.localizedDescription)
                }
            }
        }
    }
}
