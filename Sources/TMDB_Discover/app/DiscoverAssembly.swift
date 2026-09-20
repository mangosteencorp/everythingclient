import CoreFeatures
import Swinject
import TMDB_Shared_Backend

public class DiscoverAssembly: Assembly {
    private let apiKey: String

    public init(apiKey: String) {
        self.apiKey = apiKey
    }

    public func assemble(container: Container) {
        // Captured locally: the registration closure escapes, and capturing `self` would tie
        // every resolved service to this assembly's lifetime.
        let apiKey = apiKey

        // Register API Service
        container.register(APIServiceProtocol.self) { resolver in
            if let apiService = resolver.resolve(TMDBAPIService.self) {
                return apiService
            }
            return TMDBAPIService(apiKey: apiKey)
        }.inObjectScope(.container)

        // Register Repository
        container.register(DiscoverRepository.self) { resolver in
            MovieRepositoryImpl(apiService: resolver.resolve(APIServiceProtocol.self)!)
        }.inObjectScope(.container)

        // Register Use Cases
        container.register(FetchNowPlayingMoviesUseCase.self) { resolver in
            FetchNowPlayingMoviesUseCase(movieRepository: resolver.resolve(DiscoverRepository.self)!)
        }

        container.register(FetchUpcomingMoviesUseCase.self) { resolver in
            FetchUpcomingMoviesUseCase(movieRepository: resolver.resolve(DiscoverRepository.self)!)
        }

        // Register Discover Use Cases
        container.register(FetchGenresUseCase.self) { resolver in
            DefaultFetchGenresUseCase(repository: resolver.resolve(DiscoverRepository.self)!)
        }

        container.register(FetchTVGenresUseCase.self) { resolver in
            DefaultFetchTVGenresUseCase(repository: resolver.resolve(DiscoverRepository.self)!)
        }

        container.register(FetchPopularPeopleUseCase.self) { resolver in
            DefaultFetchPopularPeopleUseCase(repository: resolver.resolve(DiscoverRepository.self)!)
        }

        container.register(FetchTrendingItemsUseCase.self) { resolver in
            DefaultFetchTrendingItemsUseCase(repository: resolver.resolve(DiscoverRepository.self)!)
        }

        container.register(ToggleTVShowFavoriteUseCase.self) { resolver in
            DefaultToggleTVShowFavoriteUseCase(
                movieRepository: resolver.resolve(DiscoverRepository.self)!,
                authViewModel: resolver.resolve((any AuthenticationViewModelProtocol).self)!
            )
        }

        container.register(FetchFavoriteTVShowsUseCase.self) { resolver in
            FetchFavoriteTVShowsUseCaseImpl(repository: resolver.resolve(DiscoverRepository.self)!)
        }

        container.register(FetchDiscoverMoviesUseCase.self) { resolver in
            DefaultFetchDiscoverMoviesUseCase(movieRepository: resolver.resolve(DiscoverRepository.self)!)
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

        container.register(TVFeedViewModel.self, name: "discover") { resolver in
            TVFeedViewModel(
                fetchDiscoverMoviesUseCase: resolver.resolve(FetchDiscoverMoviesUseCase.self)!,
                fetchFavoriteTVShowsUseCase: resolver.resolve(FetchFavoriteTVShowsUseCase.self),
                toggleTVShowFavoriteUseCase: resolver.resolve(ToggleTVShowFavoriteUseCase.self),
                analyticsTracker: resolver.resolve(AnalyticsTracker.self),
                authViewModel: resolver.resolve((any AuthenticationViewModelProtocol).self)
            )
        }

        // Allow resolving discover VM with initial discover parameters
        container.register(TVFeedViewModel.self, name: "discover") { (resolver: Resolver, params: DiscoverMoviesParams) in
            TVFeedViewModel(
                fetchDiscoverMoviesUseCase: resolver.resolve(FetchDiscoverMoviesUseCase.self)!,
                fetchFavoriteTVShowsUseCase: resolver.resolve(FetchFavoriteTVShowsUseCase.self),
                toggleTVShowFavoriteUseCase: resolver.resolve(ToggleTVShowFavoriteUseCase.self),
                analyticsTracker: resolver.resolve(AnalyticsTracker.self),
                authViewModel: resolver.resolve((any AuthenticationViewModelProtocol).self),
                discoverParams: params
            )
        }

        // Register HomeDiscoverViewModel
        container.register(HomeDiscoverViewModel.self) { resolver in
            HomeDiscoverViewModel(
                fetchGenresUseCase: resolver.resolve(FetchGenresUseCase.self)!,
                fetchTVGenresUseCase: resolver.resolve(FetchTVGenresUseCase.self)!,
                fetchPopularPeopleUseCase: resolver.resolve(FetchPopularPeopleUseCase.self)!,
                fetchTrendingItemsUseCase: resolver.resolve(FetchTrendingItemsUseCase.self)!,
                analyticsTracker: resolver.resolve(AnalyticsTracker.self)
            )
        }
    }
}
