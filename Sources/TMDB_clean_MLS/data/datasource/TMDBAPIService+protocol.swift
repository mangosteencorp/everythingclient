import TMDB_Shared_Backend

extension TMDBAPIService: APIServiceProtocol {

    func fetchTVShows(endpoint: TVShowListType) async -> Result<TVListResultModel, Error> {
        let listTypeEndpoint: TMDBEndpoint = {
            switch endpoint {
            case .airingToday:
                return .tvAiringToday()
            case .onTheAir:
                return .tvOnTheAir()
            }
        }()
        let result: Result<TVListResultModel, TMDBAPIError> = await request<TVListResultModel>(listTypeEndpoint)

        switch result {
        case let .success(response):
            return .success(response)
        case let .failure(error):
            return .failure(error as Error)
        }
    }
}
