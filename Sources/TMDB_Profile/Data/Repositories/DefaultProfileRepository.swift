import Foundation
import RxSwift
import TMDB_Shared_Backend

class DefaultProfileRepository: ProfileRepositoryProtocol {
    private let apiService: any TMDBAPIRequesting
    private let authRepository: AuthRepository

    init(apiService: any TMDBAPIRequesting, authRepository: AuthRepository) {
        self.apiService = apiService
        self.authRepository = authRepository
    }

    func getAccountInfo() -> Single<AccountInfoEntity> {
        asyncSingle { [weak self] in
            guard let self else { throw Self.deallocatedError }
            let accountInfo: AccountInfoModel = try await self.apiService.request(.accountInfo)
            return AccountInfoEntity(
                id: accountInfo.id,
                name: accountInfo.name,
                username: accountInfo.username,
                avatarPath: accountInfo.avatar.tmdb.avatar_path
            )
        }
    }

    func getFavoriteMovies(accountId: String) -> Single<[MovieEntity]> {
        asyncSingle { [weak self] in
            guard let self else { throw Self.deallocatedError }
            let response: MovieListResultModel = try await self.apiService
                .request(.getFavoriteMovies(accountId: accountId))
            return response.results.map { movie in
                MovieEntity(
                    id: movie.id,
                    title: movie.title,
                    overview: movie.overview,
                    posterPath: movie.poster_path,
                    voteAverage: movie.vote_average,
                    releaseDate: movie.release_date
                )
            }
        }
    }

    func getFavoriteTVShows(accountId: String) -> Single<[TVShowEntity]> {
        asyncSingle { [weak self] in
            guard let self else { throw Self.deallocatedError }
            let response: TVShowListResultModel = try await self.apiService
                .request(.getFavoriteTVShows(accountId: accountId))
            return response.results.map(Self.tvShowEntity)
        }
    }

    func getWatchlistTVShows(accountId: String) -> Single<[TVShowEntity]> {
        asyncSingle { [weak self] in
            guard let self else { throw Self.deallocatedError }
            let response: TVShowListResultModel = try await self.apiService
                .request(.getWatchlistTVShows(accountId: accountId))
            return response.results.map(Self.tvShowEntity)
        }
    }

    // MARK: - Helpers

    /// Bridges an async request into a `Single` whose disposal actually cancels the request.
    /// Returning a bare `Disposables.create()` would let a disposed subscription — `DisposeBag`
    /// teardown, `flatMapLatest`, `take(until:)` — leave the network call running.
    private func asyncSingle<T>(_ work: @escaping () async throws -> T) -> Single<T> {
        Single.create { observer in
            let task = Task {
                do {
                    let value = try await work()
                    guard !Task.isCancelled else { return }
                    observer(.success(value))
                } catch {
                    guard !Task.isCancelled else { return }
                    observer(.failure(error))
                }
            }
            return Disposables.create { task.cancel() }
        }
    }

    private static let deallocatedError = NSError(
        domain: "ProfileRepository",
        code: -1,
        userInfo: [NSLocalizedDescriptionKey: "Self is nil"]
    )

    private static func tvShowEntity(from show: TVShow) -> TVShowEntity {
        TVShowEntity(
            id: show.id,
            name: show.name,
            overview: show.overview,
            posterPath: show.poster_path,
            firstAirDate: show.first_air_date,
            voteAverage: show.vote_average
        )
    }
}
