import SwiftUI
public struct MovieDetailPage: View {
    var movie: Movie
    @ObservedObject var movieDetailViewModel = MovieDetailViewModel()
    public init(movie: Movie) {
        self.movie = movie
        self.movieDetailViewModel = movieDetailViewModel
    }
    public var body: some View {
        
        ZStack(alignment: .bottom) {
            List {
                Section {
                    MovieCoverRow(movie: getMovie())
                    // TODO: Button rows: Wishlist, Seenlist, list
                    MovieOverview(movie: getMovie())
                }
                Section {
                    if let kwList = getMovie().keywords?.keywords, kwList.count > 0 {
                        MovieKeywords(keywords: kwList)
                    }
                    MovieCreditSection(movieId: movie.id)
                }
            }
            .navigationBarTitle(Text(movie.userTitle), displayMode: .large)
            // TODO: .navigationBarItems(trailing: Button(action: onAddButton) "text.badge.plus"
            // Movie Poster row
        }.onAppear {
            movieDetailViewModel.fetchMovieDetail(movieId: movie.id)
        }
    }
    func getMovie() -> Movie {
        if case .success(let mv) = movieDetailViewModel.state {
            return mv
        }
        return movie
    }
}
