import SwiftUI
import TMDB_Shared_UI

@available(iOS 16.0, *)
struct MovieListContent<Route: Hashable>: View {
    let movies: [Movie]
    let detailRouteBuilder: (Int) -> Route
    var body: some View {
        List(movies, id: \.id) { movie in
            NavigationLink(value: detailRouteBuilder(movie.id), label: {
                MovieRow(movie: movie.toMovieRowEntity())
            })
        }.accessibilityIdentifier("MovieListContent.List")
    }
}

#if DEBUG
@available(iOS 16.0, *)
#Preview {
    MovieListContent(movies: Movie.exampleMovies, detailRouteBuilder: { _ in 0 })
}
#endif
