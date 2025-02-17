protocol APIServiceProtocol {
    func fetchTVShows(endpoint: TVShowListType) async -> Result<TVListResultModel, Error>
}

class TVShowRepositoryImpl: TVShowRepository {
    private let apiService: APIServiceProtocol

    init(apiService: APIServiceProtocol) {
        self.apiService = apiService
    }

    func fetchAiringTodayTVShows() async -> Result<[TVShowEntity], Error> {
        return await fetchTVShows(endpoint: .airingToday)
    }

    func fetchOnTheAirTVShows() async -> Result<[TVShowEntity], Error> {
        return await fetchTVShows(endpoint: .onTheAir)
    }

    private func fetchTVShows(endpoint: TVShowListType) async -> Result<[TVShowEntity], Error> {
        let result = await apiService.fetchTVShows(endpoint: endpoint)
        switch result {
        case let .success(response):
            return .success(response.results.map { self.mapAPITVShowToEntity($0) })
        case let .failure(error):
            return .failure(error)
        }
    }

    private func mapAPITVShowToEntity(_ apiTVShow: APITVShow) -> TVShowEntity {
        TVShowEntity(
            id: apiTVShow.id,
            name: apiTVShow.name,
            overview: apiTVShow.overview,
            posterPath: apiTVShow.poster_path,
            voteAverage: apiTVShow.vote_average,
            popularity: apiTVShow.popularity,
            firstAirDate: TVShowEntity.dateFormatter.date(from: apiTVShow.first_air_date ?? "")
        )
    }
} 
