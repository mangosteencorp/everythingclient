import CoreFeatures
import SwiftUI
import Swinject
import TMDB_Discover
import TMDB_Feed
import TMDB_MovieDetail
import TMDB_Shared_Backend
import TMDB_TVShowDetail
@available(iOS 16.0, *)
public struct TMDBNavigationDestinations: ViewModifier {
    let container: Container
    private var navigationInterceptor: TMDBNavigationInterceptor? {
        container.resolve(TMDBNavigationInterceptor.self)
    }

    private var analyticsTracker: AnalyticsTracker? {
        get {
            return container.resolve(AnalyticsTracker.self)
        }
    }

    @ViewBuilder
    fileprivate func destinationView(_ route: TMDBRoute) -> some View {
        switch route {
        case let .movieDetail(movie):
            MovieDetailPage(
                movieRoute: movie.toMovieDetailModel(),
                apiService: container.resolve(TMDBAPIService.self)!,
                discoverMovieByKeywordRouteBuilder: {keywordId in
                    TMDBRoute.movieList(.keyword(keywordId))
                }
            )
        case let .tvShowDetail(tvShowId):
            let api = container.resolve(TMDBAPIService.self)!
            TVShowDetailView(tvShowId: tvShowId, apiService: api)
                .environmentObject(ThemeManager.shared)
        case let .movieList(params):
            MovieFeedListPage(apiService: container.resolve(TMDBAPIService.self)!, additionalParams: params, analyticsTracker: analyticsTracker) { movie in
                TMDBRoute.movieDetail(MovieRouteModel(id: movie.id))
            } tvShowDetailRouteBuilder: { tvShow in
                TMDBRoute.tvShowDetail(tvShow.id)
            }
        case let .tvShowList(type):
            TMDB_Discover.DiscoverListPage(
                container: container,
                apiKey: container.resolve(String.self, name: "tmdbApiKey")!,
                type: type
            ) { id, mediaType in
                switch mediaType {
                case .movie:
                    TMDBRoute.movieDetail(MovieRouteModel(id: id))
                case .tv:
                    TMDBRoute.tvShowDetail(id)
                }
            }
        }
    }

    public func body(content: Content) -> some View {
        content
            .navigationDestination(for: TMDBRoute.self) { route in
                self.navigationInterceptor?.willNavigate(to: route)
                return destinationView(route)
            }
    }
}

// View extension for easier usage
@available(iOS 16.0, *)
public extension View {
    func withTMDBNavigationDestinations(container: Container) -> some View {
        modifier(TMDBNavigationDestinations(container: container))
    }
}
