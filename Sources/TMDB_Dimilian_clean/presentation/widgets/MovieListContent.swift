import SwiftUI
// Add this new struct at the end of the file
struct MovieListContent: View {
    let movies: [Movie]
    
    var body: some View {
        List(movies, id: \.id) { movie in
            MovieRow(movie: movie)
        }
        #if DEBUG
        .onAppear {
            debugPrint(movies)
        }
        #endif
    }
}
#if DEBUG
#Preview {
    MovieListContent(movies: Movie.exampleMovies)
}
#endif
