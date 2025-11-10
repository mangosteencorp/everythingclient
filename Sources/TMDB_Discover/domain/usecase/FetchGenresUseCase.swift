import Foundation

protocol FetchGenresUseCase {
    func execute() async -> Result<[Genre], Error>
}

class DefaultFetchGenresUseCase: FetchGenresUseCase {
    private let repository: DiscoverRepository

    init(repository: DiscoverRepository) {
        self.repository = repository
    }

    func execute() async -> Result<[Genre], Error> {
        return await repository.fetchGenres()
    }
}

protocol FetchTVGenresUseCase {
    func execute() async -> Result<[Genre], Error>
}

class DefaultFetchTVGenresUseCase: FetchTVGenresUseCase {
    private let repository: DiscoverRepository

    init(repository: DiscoverRepository) {
        self.repository = repository
    }

    func execute() async -> Result<[Genre], Error> {
        return await repository.fetchTVGenres()
    }
}
