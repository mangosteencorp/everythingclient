// iOS-only module: nothing in a macOS build depends on it (see `Package.swift`), but
// Xcode compiles every target of a local package regardless of reachability, so the
// guard is what actually keeps this out of the macOS build. It compiles to an empty
// module there. Removing these guards is the payoff of extracting a separate,
// iOS-only Package.swift.
#if canImport(UIKit)
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
#endif
