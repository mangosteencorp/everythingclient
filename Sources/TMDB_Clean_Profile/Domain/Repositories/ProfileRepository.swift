import Combine
import Foundation
import TMDB_Shared_Backend

protocol ProfileRepositoryProtocol {
    func getAccountInfo() -> AnyPublisher<AccountInfoEntity, Error>
    func getFavoriteMovies(accountId: String) -> AnyPublisher<[MovieEntity], Error>
    func getFavoriteTVShows(accountId: String) -> AnyPublisher<[TVShowEntity], Error>
    func getWatchlistTVShows(accountId: String) -> AnyPublisher<[TVShowEntity], Error>
}
