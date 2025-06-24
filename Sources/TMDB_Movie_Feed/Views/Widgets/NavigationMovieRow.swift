import SwiftUI
import TMDB_Shared_UI

@available(iOS 16.0, *)
struct NavigationMovieRow<Route: Hashable>: View {
    @ObservedObject var viewModel: MovieFeedViewModel
    let movie: Movie
    let routeBuilder: (Movie) -> Route

    init(_ viewModel: MovieFeedViewModel, movie: Movie, routeBuilder: @escaping (Movie) -> Route) {
        self.viewModel = viewModel
        self.movie = movie
        self.routeBuilder = routeBuilder
    }

    var body: some View {
        NavigationLink(value: routeBuilder(movie), label: {
            MovieRow(movie: movie.toMovieRowEntity())
        })
        .accessibilityIdentifier("movielist1.movierow\(movie.id)")
        .onAppear {
            debugPrint("onAppear \(movie.id):\(movie.title)")
            viewModel.fetchMoreContentIfNeeded(currentMovieId: movie.id)
        }
    }
}
