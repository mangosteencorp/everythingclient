import Swinject
import TMDB_Shared_Backend

public class ProfileAssembly: Assembly {
    public func assemble(container: Container) {
        // Repository
        container.register(ProfileRepositoryProtocol.self) { resolver in
            let apiService = resolver.resolve(TMDBAPIService.self)!
            let authRepository = resolver.resolve(AuthRepository.self)!
            return DefaultProfileRepository(apiService: apiService, authRepository: authRepository)
        }
        
        // Use Case
        container.register(GetProfileUseCaseProtocol.self) { resolver in
            let repository = resolver.resolve(ProfileRepositoryProtocol.self)!
            return DefaultGetProfileUseCase(repository: repository)
        }
        
        // View Model
        container.register(ProfileViewModel.self) { resolver in
            let useCase = resolver.resolve(GetProfileUseCaseProtocol.self)!
            let authViewModel = resolver.resolve(AuthenticationViewModel.self)!
            return ProfileViewModel(getProfileUseCase: useCase, authViewModel: authViewModel)
        }
        
        
    }
} 
