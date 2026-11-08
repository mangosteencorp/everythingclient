import SwiftUI
import TMDB_Shared_Backend

/// Movie detail pages side by side: swipe sideways to the previous or next movie of the list
/// the user came from. Pages are built lazily, each owning its view models, so a movie only
/// loads once its page scrolls into view. A single movie is shown as a plain page.
@available(iOS 17.0, *)
public struct MovieDetailPager<Page: View>: View {
    let movies: [Movie]
    @State private var currentMovieId: Int?
    @ViewBuilder let page: (Movie) -> Page

    init(movies: [Movie], selectedMovieId: Int, @ViewBuilder page: @escaping (Movie) -> Page) {
        self.movies = movies
        _currentMovieId = State(initialValue: selectedMovieId)
        self.page = page
    }

    public var body: some View {
        if movies.count > 1 {
            pager
        } else if let movie = movies.first {
            page(movie)
        }
    }

    private var pager: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(movies) { movie in
                    page(movie)
                        .containerRelativeFrame(.horizontal)
                }
            }
            .scrollTargetLayout()
            // A page's own title would win over the pager's and stay on the first page built.
            .environment(\.movieDetailPageTitlesItself, false)
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $currentMovieId)
        .scrollIndicators(.hidden)
        .navigationTitle(currentMovie?.userTitle ?? "")
        // A large title would follow the horizontal scroll view, not the page's list.
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("movieDetail.pager")
    }

    private var currentMovie: Movie? {
        movies.first { $0.id == currentMovieId }
    }
}

extension EnvironmentValues {
    /// Off inside `MovieDetailPager`, which titles the bar for whichever page is on screen.
    @Entry var movieDetailPageTitlesItself = true
}

/// A movie page's own large title, left out when a pager titles the bar instead.
struct MovieDetailPageTitle: ViewModifier {
    @Environment(\.movieDetailPageTitlesItself) private var titlesItself
    let title: String

    func body(content: Content) -> some View {
        if titlesItself {
            content.navigationBarTitle(Text(title), displayMode: .large)
        } else {
            content
        }
    }
}

@available(iOS 17.0, *)
public extension MovieDetailPager {
    /// Pages through `movies` starting at `selectedMovieId`, every page a `MovieDetailPage`
    /// with the same routes.
    init<Route: Hashable>(
        movies: [Movie],
        selectedMovieId: Int,
        apiService: TMDBAPIService,
        discoverMovieByKeywordRouteBuilder: @escaping (Int) -> Route,
        personRouteBuilder: ((Int) -> Route)? = nil,
        photoSlidesRouteBuilder: (([String], Int) -> Route)? = nil,
        pokedexRouteBuilder: (() -> Route)? = nil
    ) where Page == MovieDetailPage<Route> {
        self.init(movies: movies, selectedMovieId: selectedMovieId) { movie in
            MovieDetailPage(
                movieRoute: movie,
                apiService: apiService,
                discoverMovieByKeywordRouteBuilder: discoverMovieByKeywordRouteBuilder,
                personRouteBuilder: personRouteBuilder,
                photoSlidesRouteBuilder: photoSlidesRouteBuilder,
                pokedexRouteBuilder: pokedexRouteBuilder
            )
        }
    }
}

#if DEBUG
#Preview("Pager") {
    TMDBMovieDetailPreviewCatalog.pager.view
}
#endif
