import CoreFeatures
import Swinject
import TMDB_Shared_Backend

public class MovieAssembly: Assembly {
    public init() {}

    public func assemble(container: Container) {
        // Register API Service
        container.register(APIServiceProtocol.self) { _ in
            TMDBAPIService(apiKey: APIKeys.tmdbKey)
        }.inObjectScope(.container)

        // Register Repository
        container.register(MovieRepository.self) { resolver in
            MovieRepositoryImpl(apiService: resolver.resolve(APIServiceProtocol.self)!)
        }.inObjectScope(.container)

        // Register Use Cases
        container.register(FetchNowPlayingMoviesUseCase.self) { resolver in
            FetchNowPlayingMoviesUseCase(movieRepository: resolver.resolve(MovieRepository.self)!)
        }

        container.register(FetchUpcomingMoviesUseCase.self) { resolver in
            FetchUpcomingMoviesUseCase(movieRepository: resolver.resolve(MovieRepository.self)!)
        }

        // Register ViewModels
        container.register(MoviesViewModel.self, name: "nowPlaying") { resolver in
            MoviesViewModel(
                fetchMoviesUseCase: resolver.resolve(FetchNowPlayingMoviesUseCase.self)!,
                analyticsTracker: resolver.resolve(AnalyticsTracker.self),
                screenName: "nowPlaying"
            )
        }

        container.register(MoviesViewModel.self, name: "upcoming") { resolver in
            MoviesViewModel(
                fetchMoviesUseCase: resolver.resolve(FetchUpcomingMoviesUseCase.self)!,
                analyticsTracker: resolver.resolve(AnalyticsTracker.self),
                screenName: "upcoming"
            )
        }
    }
}
