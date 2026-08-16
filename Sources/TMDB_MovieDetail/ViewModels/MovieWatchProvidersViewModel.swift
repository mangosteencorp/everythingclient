import SwiftUI
import TMDB_Shared_Backend
import TMDB_Shared_UI

public typealias MovieWatchProvidersState = LoadState<WatchProviderResponse>

@MainActor
public class MovieWatchProvidersViewModel: ObservableObject {
    @Published var state: MovieWatchProvidersState = .initial

    private let apiService: TMDBAPIService

    public init(apiService: TMDBAPIService) {
        self.apiService = apiService
    }

    func load(movieId: Int) async {
        guard state.isInitial else { return }
        await fetch(movieId: movieId)
    }

    func reload(movieId: Int) async {
        guard !state.isLoading else { return }
        await fetch(movieId: movieId)
    }

    private func fetch(movieId: Int) async {
        state = .loading
        let result: Result<WatchProviderResponse, TMDBAPIError> = await apiService.request(.watchProviders(movie: movieId))
        guard !Task.isCancelled else {
            state = .initial
            return
        }
        switch result {
        case let .success(watchProviders):
            state = .success(watchProviders)
        case let .failure(error):
            state = .error(error.localizedDescription)
        }
    }
}
