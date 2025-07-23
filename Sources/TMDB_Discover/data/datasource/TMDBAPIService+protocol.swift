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

    func fetchGenres() async -> Result<GenreListModel, Error> {
        let result: Result<GenreListModel, TMDBAPIError> = await request(.genres)
        switch result {
        case let .success(response):
            return .success(response)
        case let .failure(error):
            return .failure(error as Error)
        }
    }

    func fetchPopularPeople() async -> Result<PersonListResultModel, Error> {
        let result: Result<PersonListResultModel, TMDBAPIError> = await request(.popularPersons)
        switch result {
        case let .success(response):
            return .success(response)
        case let .failure(error):
            return .failure(error as Error)
        }
    }

    func fetchTrendingItems() async -> Result<TrendingAllResultModel, Error> {
        let result: Result<TrendingAllResultModel, TMDBAPIError> = await request(.trendingAll())
        switch result {
        case let .success(response):
            return .success(response)
        case let .failure(error):
            return .failure(error as Error)
        }
    }
}
