import SwiftUI
import TMDB_Shared_Backend
import TMDB_Shared_UI

typealias MovieDetailState = LoadState<Movie>

@MainActor
class MovieDetailViewModel: ObservableObject {
    @Published var state: MovieDetailState = .initial

    private let apiService: any TMDBAPIRequesting
    init(apiService: any TMDBAPIRequesting) {
        self.apiService = apiService
    }

    /// No-op unless nothing has been attempted yet, so several `.task` modifiers can call it safely.
    func load(movieId: Int) async {
        guard state.isInitial else { return }
        await fetch(movieId: movieId)
    }

    /// User driven retry. Refuses to stack on a request that is already in flight.
    func reload(movieId: Int) async {
        guard !state.isLoading else { return }
        await fetch(movieId: movieId)
    }

    private func fetch(movieId: Int) async {
        state = .loading
        let result: Result<Movie, TMDBAPIError> = await apiService.request(.movieDetail(movie: movieId))
        // A cancelled request comes back as a failure. Storing it would leave `load` permanently
        // blocked, so go back to `initial` and let the next appearance start over.
        guard !Task.isCancelled else {
            state = .initial
            return
        }
        switch result {
        case let .success(movieDetail):
            state = .success(movieDetail)
        case let .failure(error):
            state = .error(error.localizedDescription)
        }
    }
}
