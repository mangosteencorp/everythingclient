class FetchNowPlayingMoviesUseCase: FetchMoviesUseCase {
    private let movieRepository: DiscoverRepository

    init(movieRepository: DiscoverRepository) {
        self.movieRepository = movieRepository
    }

    func execute() async -> Result<[Movie], Error> {
        return await movieRepository.fetchNowPlayingMovies()
    }
}
