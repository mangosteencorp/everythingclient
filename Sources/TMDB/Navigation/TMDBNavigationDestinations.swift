import CoreFeatures
import PhotoListViewer
import Pokedex
import SwiftUI
import Swinject
import TMDB_Feed
import TMDB_MovieDetail
import TMDB_Person
import TMDB_Shared_Backend
import TMDB_Shared_UI
import TMDB_TVShowDetail
// UIKit-backed module, iOS only; see `Package.swift`.
#if os(iOS)
import TMDB_Discover
#endif
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
    func destinationView(_ route: TMDBRoute) -> some View {
        switch route {
        case let .movieDetail(movie):
            MovieDetailPage(
                movieRoute: movie.toMovieDetailModel(),
                apiService: container.resolve(TMDBAPIService.self)!,
                discoverMovieByKeywordRouteBuilder: {keywordId in
                    TMDBRoute.movieList(.keyword(keywordId))
                },
                personRouteBuilder: { personId in
                    TMDBRoute.personDetail(personId)
                },
                photoSlidesRouteBuilder: { imagePaths, initialIndex in
                    TMDBRoute.photoSlides(PhotoSlidesRouteModel(imagePaths: imagePaths, initialIndex: initialIndex))
                },
                pokedexRouteBuilder: {
                    TMDBRoute.pokedex
                }
            )
        case let .tvShowDetail(tvShowId):
            let api = container.resolve(TMDBAPIService.self)!
            TVShowDetailView(tvShowId: tvShowId, apiService: api)
                .environmentObject(ThemeManager.shared)
        case let .personDetail(personId):
            PersonDetailPage(
                personId: personId,
                apiService: container.resolve(TMDBAPIService.self)!,
                movieRouteBuilder: { movieId in
                    TMDBRoute.movieDetail(MovieRouteModel(id: movieId))
                }
            )
            .zoomTransitionDestination(id: TMDBRoute.personDetail(personId))
        case let .photoSlides(model):
            PhotoSlidesPage(imagePaths: model.imagePaths, initialIndex: model.initialIndex)
        case .pokedex:
            PokedexView()
                .navigationTitle("Pokédex")
        case let .movieList(params):
            MovieFeedListPage(apiService: container.resolve(TMDBAPIService.self)!, additionalParams: params, analyticsTracker: analyticsTracker) { movie in
                TMDBRoute.movieDetail(MovieRouteModel(id: movie.id))
            } tvShowDetailRouteBuilder: { tvShow in
                TMDBRoute.tvShowDetail(tvShow.id)
            }
        #if os(iOS)
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
        #endif
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

/// Renders a route as a standalone page — used by the column-based shells, which show a route
/// as the *root* of another column instead of pushing it onto a stack.
@available(iOS 16.0, *)
public struct TMDBRouteView: View {
    let route: TMDBRoute
    let container: Container

    public init(route: TMDBRoute, container: Container) {
        self.route = route
        self.container = container
    }

    public var body: some View {
        TMDBNavigationDestinations(container: container).destinationView(route)
    }
}

// View extension for easier usage
@available(iOS 16.0, *)
public extension View {
    func withTMDBNavigationDestinations(container: Container) -> some View {
        modifier(TMDBNavigationDestinations(container: container))
    }
}
