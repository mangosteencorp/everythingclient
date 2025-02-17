import TMDB_Shared_Backend

protocol APIServiceProtocol {
    func fetchMovies(endpoint: MovieListType) async -> Result<MovieListResultModel, Error>
}

class MovieRepositoryImpl: MovieRepository {
    private let apiService: APIServiceProtocol

    init(apiService: APIServiceProtocol) {
        self.apiService = apiService
    }

    func fetchNowPlayingMovies() async -> Result<[Movie], Error> {
        return await fetchMovies(endpoint: .nowPlaying)
    }

    func fetchUpcomingMovies() async -> Result<[Movie], Error> {
        return await fetchMovies(endpoint: .upcoming)
    }

    private func fetchMovies(endpoint: MovieListType) async -> Result<[Movie], Error> {
        let result = await apiService.fetchMovies(endpoint: endpoint)
        switch result {
        case let .success(response):
            return .success(response.results.map { self.mapAPIMovieToEntity($0) })
        case let .failure(error):
            return .failure(error)
        }
    }

    private func mapAPIMovieToEntity(_ apiMovie: APIMovie) -> Movie {
        // Map API model to domain entity (same as before)
        Movie(
            id: apiMovie.id,
            title: apiMovie.title,
            overview: apiMovie.overview,
            posterPath: apiMovie.poster_path,
            voteAverage: apiMovie.vote_average,
            popularity: apiMovie.popularity,
            releaseDate: Movie.dateFormatter.date(from: apiMovie.release_date ?? "")
        )
    }
}
