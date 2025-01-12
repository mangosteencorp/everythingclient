import TMDB_Shared_Backend
protocol APIServiceProtocol {
    func fetchMovies(endpoint: MovieListType) async -> Result<MovieListResultModel, Error>
}

extension TMDBAPIService: APIServiceProtocol {
    func fetchMovies(endpoint: MovieListType) async -> Result<MovieListResultModel, Error> {
        let listTypeEndpoint: TMDBEndpoint = {
            switch endpoint {
            case .nowPlaying:
                return .nowPlaying()
            case .upcoming:
                return .upcoming()
            }
        }()
        let result: Result<MovieListResultModel, TMDBAPIError> = await request<MovieListResultModel>(listTypeEndpoint)
        
        // Map TMDBAPIError to Error
        switch result {
        case .success(let response):
            return .success(response)
        case .failure(let error):
            return .failure(error as Error)
        }
    }
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
            case .success(let response):
                return .success(response.results.map { self.mapAPIMovieToEntity($0) })
            case .failure(let error):
                return .failure(error)
            }
        }
    
    private func mapAPIMovieToEntity(_ apiMovie: APIMovie) -> Movie {
        // Map API model to domain entity (same as before)
        Movie(id: apiMovie.id,
              title: apiMovie.title,
              overview: apiMovie.overview,
              posterPath: apiMovie.poster_path,
              voteAverage: apiMovie.vote_average,
              popularity: apiMovie.popularity,
              releaseDate: Movie.dateFormatter.date(from: apiMovie.release_date ?? ""))
    }
}
