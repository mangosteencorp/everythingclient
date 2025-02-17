protocol FetchTVShowsUseCase {
    func execute() async -> Result<[TVShowEntity], Error>
}

class FetchAiringTodayTVShowsUseCase: FetchTVShowsUseCase {
    private let tvShowRepository: TVShowRepository

    init(tvShowRepository: TVShowRepository) {
        self.tvShowRepository = tvShowRepository
    }

    func execute() async -> Result<[TVShowEntity], Error> {
        return await tvShowRepository.fetchAiringTodayTVShows()
    }
}

class FetchOnTheAirTVShowsUseCase: FetchTVShowsUseCase {
    private let tvShowRepository: TVShowRepository

    init(tvShowRepository: TVShowRepository) {
        self.tvShowRepository = tvShowRepository
    }

    func execute() async -> Result<[TVShowEntity], Error> {
        return await tvShowRepository.fetchOnTheAirTVShows()
    }
} 
