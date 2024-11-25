import SwiftUI
import Combine

enum MovieDetailState {
    case loading
    case success(Movie)
    case error(String)
}

class MovieDetailViewModel: ObservableObject {
    @Published var state: MovieDetailState = .loading

    private var cancellables = Set<AnyCancellable>()
    private let apiService = APIService.shared
    
    func fetchMovieDetail(movieId: Int) {
        state = .loading
        
        Task {
            let result = await self.apiService.fetchMovieDetail(movieId: movieId)
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
