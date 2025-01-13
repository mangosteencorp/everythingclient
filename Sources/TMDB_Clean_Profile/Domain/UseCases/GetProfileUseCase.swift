import Foundation
import Combine

protocol GetProfileUseCaseProtocol {
    func execute() -> AnyPublisher<ProfileEntity, Error>
}

class DefaultGetProfileUseCase: GetProfileUseCaseProtocol {
    private let repository: ProfileRepositoryProtocol
    
    init(repository: ProfileRepositoryProtocol) {
        self.repository = repository
    }
    
    func execute() -> AnyPublisher<ProfileEntity, Error> {
        repository.getAccountInfo()
            .flatMap { accountInfo -> AnyPublisher<ProfileEntity, Error> in
                let accountId = String(accountInfo.id)
                
                return Publishers.CombineLatest3(
                    self.repository.getFavoriteMovies(accountId: accountId),
                    self.repository.getFavoriteTVShows(accountId: accountId),
                    self.repository.getWatchlistTVShows(accountId: accountId)
                )
                .map { movies, tvShows, watchlist in
                    ProfileEntity(
                        accountInfo: accountInfo,
                        favoriteMovies: movies,
                        favoriteTVShows: tvShows,
                        watchlistTVShows: watchlist
                    )
                }
                .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
} 