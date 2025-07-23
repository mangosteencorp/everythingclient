import Foundation
import RxSwift
import TMDB_Shared_Backend

class DefaultProfileRepository: ProfileRepositoryProtocol {
    private let apiService: TMDBAPIService
    private let authRepository: AuthRepository

    init(apiService: TMDBAPIService, authRepository: AuthRepository) {
        self.apiService = apiService
        self.authRepository = authRepository
    }

    func getAccountInfo() -> Single<AccountInfoEntity> {
        Single.create { [weak self] observer in
            guard let self = self else {
                observer(.failure(NSError(domain: "ProfileRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "Self is nil"])))
                return Disposables.create()
            }

            Task {
                do {
                    let accountInfo: AccountInfoModel = try await self.apiService.request(.accountInfo)
                    let entity = AccountInfoEntity(
                        id: accountInfo.id,
                        name: accountInfo.name,
                        username: accountInfo.username,
                        avatarPath: accountInfo.avatar.tmdb.avatar_path
                    )
                    observer(.success(entity))
                } catch {
                    observer(.failure(error))
                }
            }

            return Disposables.create()
        }
    }

    func getFavoriteMovies(accountId: String) -> Single<[MovieEntity]> {
        Single.create { [weak self] observer in
            guard let self = self else {
                observer(.failure(NSError(domain: "ProfileRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "Self is nil"])))
                return Disposables.create()
            }

            Task {
                do {
                    let response: MovieListResultModel = try await self.apiService
                        .request(.getFavoriteMovies(accountId: accountId))
                    let entities = response.results.map { movie in
                        MovieEntity(
                            id: movie.id,
                            title: movie.title,
                            overview: movie.overview,
                            posterPath: movie.poster_path,
                            voteAverage: movie.vote_average,
                            releaseDate: movie.release_date
                        )
                    }
                    observer(.success(entities))
                } catch {
                    observer(.failure(error))
                }
            }

            return Disposables.create()
        }
    }

    func getFavoriteTVShows(accountId: String) -> Single<[TVShowEntity]> {
        Single.create { [weak self] observer in
            guard let self = self else {
                observer(.failure(NSError(domain: "ProfileRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "Self is nil"])))
                return Disposables.create()
            }

            Task {
                do {
                    let response: TVShowListResultModel = try await self.apiService
                        .request(.getFavoriteTVShows(accountId: accountId))
                    let entities = response.results.map { show in
                        TVShowEntity(
                            id: show.id,
                            name: show.name,
                            overview: show.overview,
                            posterPath: show.poster_path,
                            firstAirDate: show.first_air_date,
                            voteAverage: show.vote_average
                        )
                    }
                    observer(.success(entities))
                } catch {
                    observer(.failure(error))
                }
            }

            return Disposables.create()
        }
    }

    func getWatchlistTVShows(accountId: String) -> Single<[TVShowEntity]> {
        Single.create { [weak self] observer in
            guard let self = self else {
                observer(.failure(NSError(domain: "ProfileRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "Self is nil"])))
                return Disposables.create()
            }

            Task {
                do {
                    let response: TVShowListResultModel = try await self.apiService
                        .request(.getWatchlistTVShows(accountId: accountId))
                    let entities = response.results.map { show in
                        TVShowEntity(
                            id: show.id,
                            name: show.name,
                            overview: show.overview,
                            posterPath: show.poster_path,
                            firstAirDate: show.first_air_date,
                            voteAverage: show.vote_average
                        )
                    }
                    observer(.success(entities))
                } catch {
                    observer(.failure(error))
                }
            }

            return Disposables.create()
        }
    }
}
