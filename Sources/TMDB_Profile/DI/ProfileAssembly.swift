import Swinject
import TMDB_Shared_Backend

public class ProfileAssembly: Assembly {
    public init() {}

    public func assemble(container: Container) {
        // Register Repository
        container.register(ProfileRepositoryProtocol.self) { resolver in
            let apiService = resolver.resolve(TMDBAPIService.self)!
            let authRepository = resolver.resolve(AuthRepository.self)!
            return DefaultProfileRepository(apiService: apiService, authRepository: authRepository)
        }
        .inObjectScope(.container) // Singleton scope since we want to reuse the same repository

        // Register Use Case
        container.register(GetProfileUseCaseProtocol.self) { resolver in
            let repository = resolver.resolve(ProfileRepositoryProtocol.self)!
            return DefaultGetProfileUseCase(repository: repository)
        }
        .inObjectScope(.container)

        // Register View Model
        container.register(ProfileViewModel.self) { resolver in
            let useCase = resolver.resolve(GetProfileUseCaseProtocol.self)!
            let authViewModel = resolver.resolve((any AuthenticationViewModelProtocol).self)!
            return ProfileViewModel(getProfileUseCase: useCase, authViewModel: authViewModel)
        }
        .inObjectScope(.container) // Singleton scope to maintain state

        // Register View Controllers
        container.register(ProfileViewController.self) { resolver in
            let viewModel = resolver.resolve(ProfileViewModel.self)!
            return ProfileViewController(viewModel: viewModel)
        }

        container.register(ProfileContentViewController.self) { (_, profile: ProfileEntity) in
            ProfileContentViewController(profile: profile)
        }
    }
}
