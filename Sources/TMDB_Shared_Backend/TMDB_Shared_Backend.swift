import Foundation
import Swinject
// swiftlint:disable:next type_name
public class TMDB_Shared_Backend {
    static var container: Container?

    public static func configure(container: Container, apiKey: String) {
        TMDB_Shared_Backend.container = container
        // Register API key
        container.register(String.self, name: "tmdbApiKey") { _ in apiKey }.inObjectScope(.container)
        // Register basic services
        container.register(KeychainDataSource.self) { _ in
            KeychainDataSource()
        }.inObjectScope(.container)
        // swiftlint:disable identifier_name
        container.register(AuthRepository.self) { r in
            DefaultAuthRepository(keychainDataSource: r.resolve(KeychainDataSource.self)!)
        }.inObjectScope(.container)

        container.register(TMDBAPIService.self) { r in
            TMDBAPIService(
                apiKey: apiKey,
                authRepository: r.resolve(AuthRepository.self)!
            )
        }.inObjectScope(.container)

        // Register auth services
        container.register(AuthenticationServiceProtocol.self) { r in
            AuthenticationService(
                apiService: r.resolve(TMDBAPIService.self)!,
                authRepository: r.resolve(AuthRepository.self)!
            )
        }.inObjectScope(.container)

        container.register(WebAuthenticationService.self) { _ in
            WebAuthenticationService()
        }.inObjectScope(.container)

        container.register(AuthenticationViewModel.self) { r in
            AuthenticationViewModel(
                authService: r.resolve(AuthenticationServiceProtocol.self)!,
                webAuthService: r.resolve(WebAuthenticationService.self)!
            )
        }.inObjectScope(.container)
        container.register((any AuthenticationViewModelProtocol).self) { r in
            AuthenticationViewModel(
                authService: r.resolve(AuthenticationServiceProtocol.self)!,
                webAuthService: r.resolve(WebAuthenticationService.self)!
            )
        }.inObjectScope(.container)
        // swiftlint:enable identifier_name
    }
}
