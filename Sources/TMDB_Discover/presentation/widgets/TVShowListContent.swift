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

@available(iOS 16.0, *)
struct TVShowListPageContent<Route: Hashable>: View {
    @StateObject var viewModel: TVFeedViewModel
    let type: TVShowFeedType
    let detailRouteBuilder: (Int) -> Route

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading...")
                    .id("loadingView")
            } else if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .id("errorView")
            } else {
                TVShowListContent(movies: viewModel.movies, detailRouteBuilder: detailRouteBuilder)
                    .id("movieListContent")
            }
        }
        .navigationTitle(type.title)
        .accessibilityIdentifier("movieListPage.group")
        .onFirstAppear {
            viewModel.fetchMovies()
        }
    }
}

#if DEBUG
@available(iOS 16.0, *)
#Preview {
    TVShowListContent(movies: Movie.exampleMovies, detailRouteBuilder: { _ in 0 })
}
#endif
