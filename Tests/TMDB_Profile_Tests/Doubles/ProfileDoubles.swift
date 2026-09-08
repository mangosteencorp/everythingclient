import Combine
import Foundation
import RxSwift
@testable import TMDB_Profile
import TMDB_Shared_Backend

struct ProfileTestError: Error, LocalizedError, Equatable {
    let message: String
    var errorDescription: String? { message }
}

/// Repository double whose four calls can each be seeded with a value or an error, and which records
/// the account id the use case passed down.
final class StubProfileRepository: ProfileRepositoryProtocol {
    var accountInfo: Result<AccountInfoEntity, Error> = .success(
        AccountInfoEntity(id: 42, name: "Mr Client", username: "mrclient", avatarPath: "/avatar.jpg")
    )
    var favoriteMovies: Result<[MovieEntity], Error> = .success([])
    var favoriteTVShows: Result<[TVShowEntity], Error> = .success([])
    var watchlistTVShows: Result<[TVShowEntity], Error> = .success([])

    private(set) var requestedAccountIds: [String] = []

    func getAccountInfo() -> Single<AccountInfoEntity> { single(accountInfo) }

    func getFavoriteMovies(accountId: String) -> Single<[MovieEntity]> {
        requestedAccountIds.append(accountId)
        return single(favoriteMovies)
    }

    func getFavoriteTVShows(accountId: String) -> Single<[TVShowEntity]> {
        requestedAccountIds.append(accountId)
        return single(favoriteTVShows)
    }

    func getWatchlistTVShows(accountId: String) -> Single<[TVShowEntity]> {
        requestedAccountIds.append(accountId)
        return single(watchlistTVShows)
    }

    private func single<T>(_ result: Result<T, Error>) -> Single<T> {
        switch result {
        case let .success(value): return .just(value)
        case let .failure(error): return .error(error)
        }
    }
}

/// Use case double, so the view model's state machine can be driven without the repository.
final class StubGetProfileUseCase: GetProfileUseCaseProtocol {
    var result: Result<ProfileEntity, Error> = .success(
        ProfileEntity(
            accountInfo: AccountInfoEntity(id: 42, name: "Mr Client", username: "mrclient", avatarPath: nil),
            favoriteMovies: [],
            favoriteTVShows: [],
            watchlistTVShows: []
        )
    )
    private(set) var executeCallCount = 0

    func execute() -> Single<ProfileEntity> {
        executeCallCount += 1
        switch result {
        case let .success(profile): return .just(profile)
        case let .failure(error): return .error(error)
        }
    }
}

/// Authentication double whose `@Published` flag drives the view model exactly like the real one.
final class StubAuthenticationViewModel: AuthenticationViewModelProtocol {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: Error?

    var isAuthenticatedPublisher: Published<Bool>.Publisher { $isAuthenticated }
    var isLoadingPublisher: Published<Bool>.Publisher { $isLoading }
    var errorPublisher: Published<Error?>.Publisher { $error }

    private(set) var signInCallCount = 0
    private(set) var signOutCallCount = 0

    func signIn() async {
        signInCallCount += 1
        isAuthenticated = true
    }

    func signOut() async {
        signOutCallCount += 1
        isAuthenticated = false
    }
}
