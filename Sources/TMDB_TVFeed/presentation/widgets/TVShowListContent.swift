import SwiftUI
import TMDB_Shared_UI

@available(iOS 16.0, *)
struct TVShowListContent<Route: Hashable>: View {
    let movies: [Movie]
    let detailRouteBuilder: (Int) -> Route
    var body: some View {
        List(movies, id: \.id) { movie in
            NavigationLink(value: detailRouteBuilder(movie.id), label: {
                MovieRow(movie: movie.toMovieRowEntity())
            })
        }.accessibilityIdentifier("TVShowListContent.List")
    }
}

#if DEBUG
@available(iOS 16.0, *)
#Preview {
    TVShowListContent(movies: Movie.exampleMovies, detailRouteBuilder: { _ in 0 })
}
#endif
