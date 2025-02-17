import SwiftUI
import TMDB_Shared_UI

@available(iOS 16.0, *)
struct MovieListContent<Route: Hashable>: View {
    let tvShows: [TVShowEntity]
    let detailRouteBuilder: (Int) -> Route
    var body: some View {
        List(tvShows, id: \.id) { tvShow in
            NavigationLink(value: detailRouteBuilder(tvShow.id), label: {
                MovieRow(movie: tvShow.toTVShowRowEntity())
            })
        }.accessibilityIdentifier("MovieListContent.List")
    }
}

#if DEBUG
@available(iOS 16.0, *)
#Preview {
    MovieListContent(tvShows: [], detailRouteBuilder: { _ in 0 })
}
#endif
