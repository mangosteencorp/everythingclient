import Combine
import SwiftUI
import TMDB_Shared_Backend

public enum MovieWatchProvidersState {
    case loading
    case success(WatchProviderResponse)
    case error(String)
}

public class MovieWatchProvidersViewModel: ObservableObject {
    @Published var state: MovieWatchProvidersState = .loading
    
    private var cancellables = Set<AnyCancellable>()
    private let apiService: TMDBAPIService
    
    init(apiService: TMDBAPIService) {
        self.apiService = apiService
    }
    
    func fetchWatchProviders(movieId: Int) {
        state = .loading
        Task {
            let result: Result<WatchProviderResponse, TMDBAPIError> = await apiService.request(.watchProviders(movie: movieId))
            DispatchQueue.main.async {
                switch result {
                case let .success(watchProviders):
                    self.state = .success(watchProviders)
                case let .failure(error):
                    self.state = .error(error.localizedDescription)
                }
            }
        }
    }
} 