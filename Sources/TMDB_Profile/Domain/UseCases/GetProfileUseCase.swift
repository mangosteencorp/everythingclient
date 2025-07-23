import Foundation
import RxSwift

protocol GetProfileUseCaseProtocol {
    func execute() -> Single<ProfileEntity>
}

class DefaultGetProfileUseCase: GetProfileUseCaseProtocol {
    private let repository: ProfileRepositoryProtocol

    init(repository: ProfileRepositoryProtocol) {
        self.repository = repository
    }

    func execute() -> Single<ProfileEntity> {
        repository.getAccountInfo()
            .flatMap { accountInfo -> Single<ProfileEntity> in
                let accountId = String(accountInfo.id)

                return Single.zip(
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
            }
    }
}
