import Foundation
import RxSwift
import TMDB_Shared_Backend

protocol ProfileRepositoryProtocol {
    func getAccountInfo() -> Single<AccountInfoEntity>
    func getFavoriteMovies(accountId: String) -> Single<[MovieEntity]>
    func getFavoriteTVShows(accountId: String) -> Single<[TVShowEntity]>
    func getWatchlistTVShows(accountId: String) -> Single<[TVShowEntity]>
}
