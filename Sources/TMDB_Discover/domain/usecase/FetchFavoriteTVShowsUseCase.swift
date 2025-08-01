protocol FetchFavoriteTVShowsUseCase {
    func execute() async -> Result<[Int], Error>
}

class FetchFavoriteTVShowsUseCaseImpl: FetchFavoriteTVShowsUseCase {
    private let repository: MovieRepository

    init(repository: MovieRepository) {
        self.repository = repository
    }

    func execute() async -> Result<[Int], Error> {
        return await repository.fetchFavoriteTVShows()
    }
}