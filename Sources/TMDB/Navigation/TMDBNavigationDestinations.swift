import SwiftUI
import Swinject
import TMDB_MVVM_Detail
import TMDB_MVVM_MLS
import TMDB_Shared_Backend
@available(iOS 16.0, *)
public struct TMDBNavigationDestinations: ViewModifier {
    let container: Container
    private var navigationInterceptor: TMDBNavigationInterceptor? {
        container.resolve(TMDBNavigationInterceptor.self)
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
            ).withTMDBNavigationDestinations(container: container)
        case let .tvShowDetail(tvShowId):
            Text("TV Show Detail \(tvShowId)") // Replace with actual TV show detail view
        case let .movieList(params):
            DMSNowPlayingPage(apiService: container.resolve(TMDBAPIService.self)!, additionalParams: params) { movie in
                TMDBRoute.movieDetail(MovieRouteModel(id: movie.id))
            }
            .withTMDBNavigationDestinations(container: container)
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
