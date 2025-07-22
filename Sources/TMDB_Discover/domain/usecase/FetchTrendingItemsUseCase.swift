import Foundation

protocol FetchTrendingItemsUseCase {
    func execute() async -> Result<[TrendingItem], Error>
}

class DefaultFetchTrendingItemsUseCase: FetchTrendingItemsUseCase {
    private let repository: MovieRepository
    
    init(repository: MovieRepository) {
        self.repository = repository
    }
    
    func execute() async -> Result<[TrendingItem], Error> {
        return await repository.fetchTrendingItems()
    }
}