import Foundation
import Swinject

public class TMDB_Shared_Backend {
    public static let container = Container()
    
    public static func configure(apiKey: String) {
        // Register basic services
        container.register(KeychainDataSource.self) { _ in
            KeychainDataSource()
        }.inObjectScope(.container)
        
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
    }
} 
