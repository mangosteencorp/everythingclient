import CoreFeatures
import Swinject
import TMDB_Shared_Backend

public class DiscoverAssembly: Assembly {
    public init() {}

    public func assemble(container: Container) {
        // Register API Service
        container.register(APIServiceProtocol.self) { resolver in
            if let apiService = resolver.resolve(TMDBAPIService.self) {
                return apiService
            }
            #if DEBUG
            return TMDBAPIService(apiKey: debugTMDBAPIKey)
            #else
            return TMDBAPIService(apiKey: APIKeys.tmdbKey)
            #endif
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

        // Register Discover Use Cases
        container.register(FetchGenresUseCase.self) { resolver in
            DefaultFetchGenresUseCase(repository: resolver.resolve(MovieRepository.self)!)
        }

        container.register(FetchPopularPeopleUseCase.self) { resolver in
            DefaultFetchPopularPeopleUseCase(repository: resolver.resolve(MovieRepository.self)!)
        }

        container.register(FetchTrendingItemsUseCase.self) { resolver in
            DefaultFetchTrendingItemsUseCase(repository: resolver.resolve(MovieRepository.self)!)
        }

        container.register(ToggleTVShowFavoriteUseCase.self) { resolver in
            DefaultToggleTVShowFavoriteUseCase(
                movieRepository: resolver.resolve(MovieRepository.self)!,
                authViewModel: resolver.resolve((any AuthenticationViewModelProtocol).self)!
            )
        }

        container.register(FetchFavoriteTVShowsUseCase.self) { resolver in
            FetchFavoriteTVShowsUseCaseImpl(repository: resolver.resolve(MovieRepository.self)!)
        }

        // Register ViewModels
        container.register(TVFeedViewModel.self, name: "nowPlaying") { resolver in
            TVFeedViewModel(
                fetchMoviesUseCase: resolver.resolve(FetchNowPlayingMoviesUseCase.self)!,
                fetchFavoriteTVShowsUseCase: resolver.resolve(FetchFavoriteTVShowsUseCase.self),
                toggleTVShowFavoriteUseCase: resolver.resolve(ToggleTVShowFavoriteUseCase.self),
                analyticsTracker: resolver.resolve(AnalyticsTracker.self),
                authViewModel: resolver.resolve((any AuthenticationViewModelProtocol).self)
            )
        }

        container.register(TVFeedViewModel.self, name: "upcoming") { resolver in
            TVFeedViewModel(
                fetchMoviesUseCase: resolver.resolve(FetchUpcomingMoviesUseCase.self)!,
                fetchFavoriteTVShowsUseCase: resolver.resolve(FetchFavoriteTVShowsUseCase.self),
                toggleTVShowFavoriteUseCase: resolver.resolve(ToggleTVShowFavoriteUseCase.self),
                analyticsTracker: resolver.resolve(AnalyticsTracker.self),
                authViewModel: resolver.resolve((any AuthenticationViewModelProtocol).self)
            )
        }

        // Register HomeDiscoverViewModel
        container.register(HomeDiscoverViewModel.self) { resolver in
            HomeDiscoverViewModel(
                fetchGenresUseCase: resolver.resolve(FetchGenresUseCase.self)!,
                fetchPopularPeopleUseCase: resolver.resolve(FetchPopularPeopleUseCase.self)!,
                fetchTrendingItemsUseCase: resolver.resolve(FetchTrendingItemsUseCase.self)!,
                analyticsTracker: resolver.resolve(AnalyticsTracker.self)
            )
        }
    }
}
