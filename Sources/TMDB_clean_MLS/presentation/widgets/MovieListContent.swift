import SwiftUI
import TMDB_Shared_UI
// Add this new struct at the end of the file
@available(iOS 16.0, *)
struct MovieListContent: View {
    let movies: [Movie]
    
    var body: some View {
        List(movies, id: \.id) { movie in
            NavigationLink(value: MovieDetailRoute(movie: MovieRouteModel(id: movie.id, title: movie.title, overview: movie.overview, posterPath: movie.posterPath, backdropPath: nil, voteAverage: movie.voteAverage, voteCount: 0, releaseDate: nil, popularity: movie.popularity, originalTitle: "")), label: {
                MovieRow(movie: movie)
            })
            
        }
        #if DEBUG
        .onAppear {
            debugPrint(movies)
        }
        #endif
    }
}
#if DEBUG
@available(iOS 16.0, *)
#Preview {
    MovieListContent(movies: Movie.exampleMovies)
}
#endif
