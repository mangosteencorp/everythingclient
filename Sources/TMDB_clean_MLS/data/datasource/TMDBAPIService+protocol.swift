import TMDB_Shared_Backend
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
