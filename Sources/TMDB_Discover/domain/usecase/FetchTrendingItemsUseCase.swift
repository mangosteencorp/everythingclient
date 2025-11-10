import Foundation

protocol FetchTrendingItemsUseCase {
    func execute() async -> Result<[TrendingItem], Error>
}

class DefaultFetchTrendingItemsUseCase: FetchTrendingItemsUseCase {
    private let repository: DiscoverRepository

    init(repository: DiscoverRepository) {
        self.repository = repository
    }

    func execute() async -> Result<[TrendingItem], Error> {
        return await repository.fetchTrendingItems()
    }
}
