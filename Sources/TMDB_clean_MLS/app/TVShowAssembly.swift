import Swinject
import TMDB_Shared_Backend

public class TVShowAssembly: Assembly {
    public init() {}

    public func assemble(container: Container) {
        // Register API Service
        container.register(APIServiceProtocol.self) { _ in
            TMDBAPIService(apiKey: APIKeys.tmdbKey)
        }.inObjectScope(.container)

        // Register Repository
        container.register(TVShowRepository.self) { resolver in
            TVShowRepositoryImpl(apiService: resolver.resolve(APIServiceProtocol.self)!)
        }.inObjectScope(.container)

        // Register Use Cases
        container.register(FetchAiringTodayTVShowsUseCase.self) { resolver in
            FetchAiringTodayTVShowsUseCase(tvShowRepository: resolver.resolve(TVShowRepository.self)!)
        }

        container.register(FetchOnTheAirTVShowsUseCase.self) { resolver in
            FetchOnTheAirTVShowsUseCase(tvShowRepository: resolver.resolve(TVShowRepository.self)!)
        }

        // Register ViewModels
        container.register(TVShowsViewModel.self, name: "airingToday") { resolver in
            TVShowsViewModel(fetchTVShowsUseCase: resolver.resolve(FetchAiringTodayTVShowsUseCase.self)!)
        }

        container.register(TVShowsViewModel.self, name: "onTheAir") { resolver in
            TVShowsViewModel(fetchTVShowsUseCase: resolver.resolve(FetchOnTheAirTVShowsUseCase.self)!)
        }
    }
} 
