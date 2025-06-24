import TMDB_Shared_Backend

extension TMDBAPIService: APIServiceProtocol {
    func fetchTVShows(endpoint: TVShowFeedType) async -> Result<TVShowListResultModel, Error> {
        let listTypeEndpoint: TMDBEndpoint = {
            switch endpoint {
            case .airingToday:
                return .tvAiringToday(page: nil)
            case .onTheAir:
                return .tvOnTheAir(page: nil)
            }
        }()
        let result: Result<TVShowListResultModel, TMDBAPIError> = await request<MovieListResultModel>(listTypeEndpoint)

        // Map TMDBAPIError to Error
        switch result {
        case let .success(response):
            return .success(response)
        case let .failure(error):
            return .failure(error as Error)
        }
    }
}
