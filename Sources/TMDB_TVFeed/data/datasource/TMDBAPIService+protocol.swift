import TMDB_Shared_Backend

extension TMDBAPIService: APIServiceProtocol {
    func fetchMovies(endpoint: MovieListType) async -> Result<MovieListResultModel, Error> {
        let listTypeEndpoint: TMDBEndpoint = {
            switch endpoint {
            case .nowPlaying:
                return .tvAiringToday(page: nil)
            case .upcoming:
                return .tvOnTheAir(page: nil)
            }
        }()
        let result: Result<MovieListResultModel, TMDBAPIError> = await request<MovieListResultModel>(listTypeEndpoint)

        // Map TMDBAPIError to Error
        switch result {
        case let .success(response):
            return .success(response)
        case let .failure(error):
            return .failure(error as Error)
        }
    }
}
