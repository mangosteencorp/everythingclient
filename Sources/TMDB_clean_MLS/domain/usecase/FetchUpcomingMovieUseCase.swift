class FetchUpcomingMoviesUseCase: FetchMoviesUseCase {
    private let movieRepository: MovieRepository
    
    init(movieRepository: MovieRepository) {
        self.movieRepository = movieRepository
    }
    
    func execute() async -> Result<[Movie], Error> {
        return await movieRepository.fetchUpcomingMovies()
    }
}
