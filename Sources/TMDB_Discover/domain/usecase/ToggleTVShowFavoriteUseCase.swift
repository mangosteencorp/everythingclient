protocol ToggleTVShowFavoriteUseCase {
    func execute(tvShowId: Int, isFavorite: Bool) async -> Result<Bool, Error>
}

class DefaultToggleTVShowFavoriteUseCase: ToggleTVShowFavoriteUseCase {
    private let movieRepository: MovieRepository
    
    init(movieRepository: MovieRepository) {
        self.movieRepository = movieRepository
    }
    
    func execute(tvShowId: Int, isFavorite: Bool) async -> Result<Bool, Error> {
        return await movieRepository.toggleTVShowFavorite(tvShowId: tvShowId, isFavorite: isFavorite)
    }
}