import Foundation

protocol FetchPopularPeopleUseCase {
    func execute() async -> Result<[PopularPerson], Error>
}

class DefaultFetchPopularPeopleUseCase: FetchPopularPeopleUseCase {
    private let repository: DiscoverRepository

    init(repository: DiscoverRepository) {
        self.repository = repository
    }

    func execute() async -> Result<[PopularPerson], Error> {
        return await repository.fetchPopularPeople()
    }
}
