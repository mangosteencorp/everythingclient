import Foundation
import Combine
import TMDB_Shared_Backend

class DefaultProfileRepository: ProfileRepositoryProtocol {
    private let apiService: TMDBAPIService
    private let authRepository: AuthRepository
    
    init(apiService: TMDBAPIService, authRepository: AuthRepository) {
        self.apiService = apiService
        self.authRepository = authRepository
    }
    
    func getAccountInfo() -> AnyPublisher<AccountInfoEntity, Error> {
        Future { [weak self] promise in
            guard let self = self else { return }
            Task {
                do {
                    let accountInfo: AccountInfoModel = try await self.apiService.request(.accountInfo)
                    let entity = AccountInfoEntity(
                        id: accountInfo.id,
                        name: accountInfo.name,
                        username: accountInfo.username,
                        avatarPath: accountInfo.avatar.tmdb.avatar_path
                    )
                    promise(.success(entity))
                } catch {
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func getFavoriteMovies(accountId: String) -> AnyPublisher<[MovieEntity], Error> {
        Future { [weak self] promise in
            guard let self = self else { return }
            Task {
                do {
                    let response: MovieListResultModel = try await self.apiService.request(.getFavoriteMovies(accountId: accountId))
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
                    promise(.success(entities))
                } catch {
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func getFavoriteTVShows(accountId: String) -> AnyPublisher<[TVShowEntity], Error> {
        Future { [weak self] promise in
            guard let self = self else { return }
            Task {
                do {
                    let response: TVShowListResultModel = try await self.apiService.request(.getFavoriteTVShows(accountId: accountId))
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
                    promise(.success(entities))
                } catch {
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func getWatchlistTVShows(accountId: String) -> AnyPublisher<[TVShowEntity], Error> {
        Future { [weak self] promise in
            guard let self = self else { return }
            Task {
                do {
                    let response: TVShowListResultModel = try await self.apiService.request(.getWatchlistTVShows(accountId: accountId))
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
                    promise(.success(entities))
                } catch {
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }
} 