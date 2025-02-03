import SwiftUI
import TMDB_Shared_UI
@available(iOS 16.0, *)
struct NavigationMovieRow: View {
    @ObservedObject var viewModel: NowPlayingViewModel
    let movie: Movie
    
    init(_ vm: NowPlayingViewModel, movie: Movie) {
        self.viewModel = vm
        self.movie = movie
    }
    
    var body: some View {
        NavigationLink(value: MovieDetailRoute(movie: MovieRouteModel(
            id: movie.id,
            title: movie.title,
            overview: movie.overview,
            posterPath: movie.poster_path,
            backdropPath: movie.backdrop_path,
            voteAverage: movie.vote_average,
            voteCount: movie.vote_count,
            releaseDate: movie.release_date,
            popularity: movie.popularity,
            originalTitle: movie.original_title
        )), label: {
            MovieRow(movie: movie.toMovieRowEntity())
        })
        .accessibilityIdentifier("movielist1.movierow\(movie.id)")
        .onAppear {
            debugPrint("onAppear \(movie.id):\(movie.title)")
            viewModel.fetchMoreContentIfNeeded(currentMovieId: movie.id)
        }
    }
}
