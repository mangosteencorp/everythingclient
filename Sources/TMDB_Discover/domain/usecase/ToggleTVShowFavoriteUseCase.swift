import TMDB_Shared_Backend

enum FavoriteError: Error {
    case authenticationRequired
    case apiError(Error)
}

protocol ToggleTVShowFavoriteUseCase {
    func execute(tvShowId: Int, isFavorite: Bool) async -> Result<Bool, Error>
    func requiresAuthentication() -> Bool
}

class DefaultToggleTVShowFavoriteUseCase: ToggleTVShowFavoriteUseCase {
    private let movieRepository: MovieRepository
    private let authViewModel: any AuthenticationViewModelProtocol

    init(movieRepository: MovieRepository, authViewModel: any AuthenticationViewModelProtocol) {
        self.movieRepository = movieRepository
        self.authViewModel = authViewModel
    }

    func requiresAuthentication() -> Bool {
        return !authViewModel.isAuthenticated
    }

    func execute(tvShowId: Int, isFavorite: Bool) async -> Result<Bool, Error> {
        guard authViewModel.isAuthenticated else {
            return .failure(FavoriteError.authenticationRequired)
        }

        let result = await movieRepository.toggleTVShowFavorite(tvShowId: tvShowId, isFavorite: isFavorite)
        switch result {
        case .success(let success):
            return .success(success)
        case .failure(let error):
            return .failure(FavoriteError.apiError(error))
        }
    }
}