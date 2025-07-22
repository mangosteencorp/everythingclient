import Foundation

protocol FetchGenresUseCase {
    func execute() async -> Result<[Genre], Error>
}

class DefaultFetchGenresUseCase: FetchGenresUseCase {
    private let repository: MovieRepository
    
    init(repository: MovieRepository) {
        self.repository = repository
    }
    
    func execute() async -> Result<[Genre], Error> {
        return await repository.fetchGenres()
    }
}